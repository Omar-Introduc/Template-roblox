import bpy
import bmesh
import math
import random
from mathutils import Vector, noise

# ==========================================
# CONFIGURACIÓN: ASIMETRÍA TOTAL Y BLOQUES
# ==========================================
SEGMENT_LENGTH = 20.0  
BASE_RADIUS = 30.0
POINTS_PER_RING = 10   # Pocos puntos = Caras más grandes
CAVE_LENGTH = 800.0
SEED = random.randint(0, 9999)

# Parámetros de Bloque 3D Asimétrico
BLOCK_THRESHOLD = 0.53
BLOCK_STRENGTH = 28.0
JITTER_3D = 15.0       # Aleatoriedad en X, Y y Z (Profundidad)

def get_pseudo_noise(x, y, z):
    return noise.noise(Vector((x, y, z)))

def create_ultimate_cave():
    # 1. LIMPIEZA
    if "UltimateCave" in bpy.data.objects:
        bpy.data.objects.remove(bpy.data.objects["UltimateCave"], do_unlink=True)
    if "UltimateCaveMesh" in bpy.data.meshes:
        bpy.data.meshes.remove(bpy.data.meshes["UltimateCaveMesh"], do_unlink=True)
    
    mesh = bpy.data.meshes.new("UltimateCaveMesh")
    obj = bpy.data.objects.new("UltimateCave", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    
    bm = bmesh.new()
    random.seed(SEED)

    def get_ring_verts(center_pos, index):
        verts = []
        # Desfase rotacional aleatorio por anillo para romper simetría
        rot_offset = get_pseudo_noise(index * 0.2, SEED, 5) * 10.0
        
        for i in range(POINTS_PER_RING):
            angle = (math.pi * 2 / POINTS_PER_RING) * i + rot_offset
            
            # Ruido base para la forma
            n_val = get_pseudo_noise(index * 0.15, i * 0.35, SEED)
            
            # 1. Magnitud del bloque (Radio)
            macro = 0
            if n_val > BLOCK_THRESHOLD:
                macro = math.pow(n_val - BLOCK_THRESHOLD, 0.45) * BLOCK_STRENGTH
            
            # 2. Perturbación de Profundidad (Eje Z)
            # Esto hace que cada vértice del bloque esté a una profundidad distinta
            z_offset = get_pseudo_noise(index, i, SEED + 777) * JITTER_3D
            
            # 3. Desplazamiento lateral (Ejes X e Y)
            jitter_x = get_pseudo_noise(index * 0.5, i, SEED + 888) * (JITTER_3D * 0.5)
            jitter_y = get_pseudo_noise(index * 0.5, i, SEED + 999) * (JITTER_3D * 0.5)
            
            r = BASE_RADIUS + macro
            
            x = math.cos(angle) * r + jitter_x
            y = math.sin(angle) * r + jitter_y
            z = center_pos.z + z_offset # Aquí rompemos la simetría de profundidad
            
            vert_pos = Vector((center_pos.x + x, center_pos.y + y, z))
            verts.append(bm.verts.new(vert_pos))
        return verts

    # === GENERACIÓN DE LA ESTRUCTURA ===
    steps = int(CAVE_LENGTH / SEGMENT_LENGTH)
    path_rings = []

    for i in range(steps + 1):
        # Camino principal sinuoso
        px = get_pseudo_noise(i * 0.04, SEED, 11) * 45.0
        py = get_pseudo_noise(i * 0.04, 22, SEED) * 25.0
        pz = -i * SEGMENT_LENGTH
        path_rings.append(get_ring_verts(Vector((px, py, pz)), i))

    # Construcción Intercalada (Zig-Zag)
    for i in range(len(path_rings) - 1):
        ring_a = path_rings[i]
        ring_b = path_rings[i+1]
        
        for j in range(POINTS_PER_RING):
            next_j = (j + 1) % POINTS_PER_RING
            
            # Conexión triangular para permitir deformación extrema sin errores de cara
            try:
                # Triángulo 1
                bm.faces.new((ring_a[j], ring_b[j], ring_a[next_j]))
                # Triángulo 2
                bm.faces.new((ring_b[j], ring_b[next_j], ring_a[next_j]))
            except:
                pass

    # Finalizar malla
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    # Estilo Visual de Caras Planas
    obj.data.polygons.foreach_set("use_smooth", [False] * len(obj.data.polygons))

    print(f"✅ Cueva Asimétrica Generada | Semilla: {SEED}")

create_ultimate_cave()