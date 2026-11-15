'use client';

import { Suspense, useMemo, useRef, useState } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Float, Environment, ContactShadows, AdaptiveDpr, Preload } from '@react-three/drei';
import * as THREE from 'three';

/**
 * A real 3D plate: lathe-turned geometry, physical material, floating in ember.
 *
 * No GLB to download. The plate is generated with `LatheGeometry` from a
 * profile curve, the rice mound from a scaled sphere, and the garnish from
 * instanced spheres — so the whole scene is a few hundred vertices and arrives
 * with the JS bundle.
 *
 * Three.js via @react-three/fiber. Drei supplies Float (idle motion),
 * Environment (reflections), ContactShadows (grounding) and AdaptiveDpr
 * (drops resolution instead of frame rate on weak GPUs).
 */

function PlateProfile() {
  // A shallow dish: flat base, rising rim, slightly flared lip.
  const points = useMemo(() => {
    const profile: THREE.Vector2[] = [];
    profile.push(new THREE.Vector2(0.0, -0.06));
    profile.push(new THREE.Vector2(0.62, -0.06));
    profile.push(new THREE.Vector2(0.82, 0.02));
    profile.push(new THREE.Vector2(1.02, 0.14));
    profile.push(new THREE.Vector2(1.1, 0.24));
    profile.push(new THREE.Vector2(1.06, 0.3));
    profile.push(new THREE.Vector2(0.9, 0.22));
    profile.push(new THREE.Vector2(0.7, 0.12));
    profile.push(new THREE.Vector2(0.0, 0.1));
    return profile;
  }, []);

  return (
    <mesh castShadow receiveShadow rotation={[Math.PI / 2, 0, 0]}>
      <latheGeometry args={[points, 72]} />
      <meshPhysicalMaterial
        color="#F6EFE4"
        roughness={0.42}
        metalness={0}
        clearcoat={0.6}
        clearcoatRoughness={0.35}
        side={THREE.DoubleSide}
      />
    </mesh>
  );
}

function Food() {
  // Rice mound + a ring of garnish. Instanced so it stays cheap.
  const garnish = useMemo(() => {
    const positions: [number, number, number][] = [];
    const colors = ['#E8551A', '#F26522', '#FFB347', '#C2560A', '#11543A'];
    const picked: string[] = [];
    for (let i = 0; i < 14; i += 1) {
      const angle = (i / 14) * Math.PI * 2 + 0.3;
      const radius = 0.34 + ((i * 7) % 11) * 0.018;
      positions.push([Math.cos(angle) * radius, 0.19 + ((i * 3) % 5) * 0.012, Math.sin(angle) * radius]);
      picked.push(colors[i % colors.length]);
    }
    return { positions, colors: picked };
  }, []);

  return (
    <group>
      {/* Rice */}
      <mesh position={[0, 0.14, 0]} scale={[0.62, 0.26, 0.62]} castShadow receiveShadow>
        <sphereGeometry args={[1, 40, 28, 0, Math.PI * 2, 0, Math.PI / 2]} />
        <meshStandardMaterial color="#FBF3E4" roughness={0.85} metalness={0} />
      </mesh>

      {/* Spiced skewer of meat across the top */}
      <mesh position={[0, 0.31, 0]} rotation={[0, 0.4, 0.06]} castShadow>
        <capsuleGeometry args={[0.075, 1.05, 6, 18]} />
        <meshStandardMaterial color="#8A3B12" roughness={0.55} metalness={0.08} />
      </mesh>

      {/* Garnish ring */}
      {garnish.positions.map((position, index) => (
        <mesh key={index} position={position} castShadow>
          <sphereGeometry args={[0.062, 14, 12]} />
          <meshStandardMaterial
            color={garnish.colors[index]}
            roughness={0.5}
            metalness={0.05}
          />
        </mesh>
      ))}
    </group>
  );
}

function Scene({ still }: { still: boolean }) {
  const group = useRef<THREE.Group>(null);
  const { pointer } = useThree();

  useFrame((state, delta) => {
    if (!group.current || still) return;
    // Ease toward the pointer rather than snapping — reads as weight.
    const targetY = pointer.x * 0.35;
    const targetX = -pointer.y * 0.18;
    group.current.rotation.y += (targetY - group.current.rotation.y) * Math.min(1, delta * 2.2);
    group.current.rotation.x += (targetX - group.current.rotation.x) * Math.min(1, delta * 2.2);
    group.current.position.y = Math.sin(state.clock.elapsedTime * 0.7) * 0.045;
  });

  return (
    <group ref={group}>
      <Float speed={still ? 0 : 1.1} rotationIntensity={still ? 0 : 0.12} floatIntensity={still ? 0 : 0.35}>
        <group rotation={[0.36, 0, 0]} scale={1.5}>
          <PlateProfile />
          <Food />
        </group>
      </Float>
      <ContactShadows
        position={[0, -0.75, 0]}
        opacity={0.42}
        scale={5}
        blur={2.6}
        far={2.4}
        color="#16100B"
      />
    </group>
  );
}

export default function PlateScene({ className }: { className?: string }) {
  const [still, setStill] = useState(false);

  return (
    <div className={className}>
      <Canvas
        shadows
        dpr={[1, 1.75]}
        camera={{ position: [0, 1.15, 3.5], fov: 38 }}
        gl={{ antialias: true, alpha: true, powerPreference: 'low-power' }}
        onCreated={({ gl }) => {
          gl.toneMapping = THREE.ACESFilmicToneMapping;
          gl.toneMappingExposure = 1.15;
          if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) setStill(true);
        }}
      >
        <color attach="background" args={['#16100B']} />
        <fog attach="fog" args={['#16100B', 6, 12]} />

        <ambientLight intensity={0.55} />
        {/* Warm key from the upper right, the "window" light */}
        <directionalLight
          position={[3.2, 4.4, 2.6]}
          intensity={2.6}
          color="#FFD9A8"
          castShadow
          shadow-mapSize={[1024, 1024]}
        />
        {/* Orange bounce from below-left, so the plate never goes flat */}
        <pointLight position={[-2.8, -1.2, 1.8]} intensity={9} color="#F26522" distance={9} decay={2} />
        {/* Cool rim from behind to separate the plate from the ember */}
        <pointLight position={[0, 1.4, -3.2]} intensity={5} color="#7FA8FF" distance={9} decay={2} />

        <Suspense fallback={null}>
          <Scene still={still} />
          <Environment preset="apartment" environmentIntensity={0.5} />
          <Preload all />
        </Suspense>
        <AdaptiveDpr pixelated={false} />
      </Canvas>
    </div>
  );
}
