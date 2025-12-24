let scene, camera, renderer, minecartGroup;

function init() {
    // 1. ESCENA Y CÁMARA
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1a1a);
    camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.set(6, 5, 8);
    camera.lookAt(0, 1, 0);

    // 2. RENDERER
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    // 3. ILUMINACIÓN
    scene.add(new THREE.AmbientLight(0xffffff, 0.5));
    const sun = new THREE.DirectionalLight(0xffffff, 1);
    sun.position.set(5, 10, 5);
    scene.add(sun);

    // 4. GRUPO Y MATERIALES
    minecartGroup = new THREE.Group();
    scene.add(minecartGroup);

    const matBody = new THREE.MeshStandardMaterial({ color: 0xA04030, flatShading: true });
    const matIron = new THREE.MeshStandardMaterial({ color: 0x2A2A2A, flatShading: true, metalness: 0.6, roughness: 0.4 });
    const matRock = new THREE.MeshStandardMaterial({ color: 0x151515, flatShading: true });

    // 5. CONSTRUCCIÓN: CUERPO (TRAPEZOIDE)
    const boxWidth = 2.2, boxHeight = 1.4, boxDepth = 3.2;
    const bodyGeo = new THREE.BoxGeometry(boxWidth, boxHeight, boxDepth, 1, 1, 1);
    const posAttr = bodyGeo.attributes.position;
    for (let i = 0; i < posAttr.count; i++) {
        const y = posAttr.getY(i);
        if (y < 0) {
            posAttr.setX(i, posAttr.getX(i) * 0.85);
            posAttr.setZ(i, posAttr.getZ(i) * 0.85);
        }
    }
    bodyGeo.computeVertexNormals();
    const cartBody = new THREE.Mesh(bodyGeo, matBody);
    cartBody.position.y = 1.2;
    minecartGroup.add(cartBody);

    // 6. COSTILLAS
    const createRib = (x, z, rotX = 0, rotZ = 0) => {
        const ribGeo = new THREE.BoxGeometry(0.15, boxHeight, 0.15);
        const rib = new THREE.Mesh(ribGeo, matBody);
        rib.position.set(x, 1.2, z);
        rib.rotation.x = rotX;
        rib.rotation.z = rotZ;
        minecartGroup.add(rib);
    };
    [-1.4, -0.5, 0.5, 1.4].forEach(z => {
        createRib(1.05, z, 0, -0.1);
        createRib(-1.05, z, 0, 0.1);
    });
    [-0.6, 0.6].forEach(x => {
        createRib(x, 1.55, 0.1, 0);
        createRib(x, -1.55, -0.1, 0);
    });

    // 7. CHASIS Y BORDE
    const rimGeo = new THREE.BoxGeometry(boxWidth + 0.2, 0.15, boxDepth + 0.2);
    const rim = new THREE.Mesh(rimGeo, matIron);
    rim.position.y = 1.2 + (boxHeight / 2);
    minecartGroup.add(rim);

    const chassisGeo = new THREE.BoxGeometry(boxWidth * 0.9, 0.2, boxDepth * 0.9);
    const chassis = new THREE.Mesh(chassisGeo, matIron);
    chassis.position.y = 0.5;
    minecartGroup.add(chassis);

    // 8. RUEDAS
    const createWheelSet = (z) => {
        const wheelGeo = new THREE.CylinderGeometry(0.4, 0.4, 0.25, 12);
        const axleGeo = new THREE.CylinderGeometry(0.1, 0.1, 2.4, 8);
        const axle = new THREE.Mesh(axleGeo, matIron);
        axle.rotation.z = Math.PI / 2;
        axle.position.set(0, 0.3, z);
        minecartGroup.add(axle);
        [1.1, -1.1].forEach(x => {
            const w = new THREE.Mesh(wheelGeo, matIron);
            w.rotation.z = Math.PI / 2;
            w.position.set(x, 0.3, z);
            minecartGroup.add(w);
        });
    };
    createWheelSet(1.0);
    createWheelSet(-1.0);

    // 9. CARBÓN
    const rockGeo = new THREE.IcosahedronGeometry(0.3, 0);
    for (let i = 0; i < 45; i++) {
        const rock = new THREE.Mesh(rockGeo, matRock);
        const rx = (Math.random() - 0.5) * 1.6;
        const rz = (Math.random() - 0.5) * 2.6;
        const dist = Math.sqrt(rx * rx + rz * rz);
        const hBias = Math.max(0, 0.6 - dist * 0.3);
        rock.position.set(rx, 1.4 + Math.random() * 0.2 + hBias, rz);
        rock.rotation.set(Math.random() * 3, Math.random() * 3, Math.random() * 3);
        rock.scale.setScalar(0.8 + Math.random());
        minecartGroup.add(rock);
    }

    animate();
}

function animate() {
    requestAnimationFrame(animate);
    minecartGroup.rotation.y += 0.005;
    renderer.render(scene, camera);
}

// Lógica del botón de descarga
document.getElementById('downloadBtn').addEventListener('click', () => {
    const exporter = new THREE.GLTFExporter();
    exporter.parse(minecartGroup, (gltf) => {
        const blob = new Blob([JSON.stringify(gltf)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'minecart_full_separado.gltf';
        link.click();
    });
});

// Arrancar
init();