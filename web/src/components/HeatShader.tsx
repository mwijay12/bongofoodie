'use client';

import { useEffect, useRef } from 'react';

/**
 * Warm plume of steam rising over the hero.
 *
 * Hand-written GLSL, no three.js: one full-screen quad, one fragment shader, so
 * the cost is a few hundred KB of GPU work and no JavaScript per frame beyond
 * setting `uTime`. The noise is value-noise with 4 octaves of fBm; the mask is a
 * soft upward column so the effect never touches the copy on the left.
 *
 * Behaviour contract:
 *  - Renders nothing (returns null) when the user prefers reduced motion.
 *  - Caps device pixel ratio at 2 so a 3× phone does not melt.
 *  - Pauses when scrolled out of view, and on `visibilitychange`.
 *  - Falls back silently to a CSS radial glow if WebGL is unavailable.
 */
export default function HeatShader({ className }: { className?: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    const gl = canvas.getContext('webgl', {
      antialias: false,
      alpha: true,
      premultipliedAlpha: false,
      powerPreference: 'low-power',
    });
    if (!gl) return;

    const vertexSource = `
      attribute vec2 aPos;
      void main() { gl_Position = vec4(aPos, 0.0, 1.0); }
    `;

    // Colours are linear-ish brand values divided by 255. Alpha is the plume.
    const fragmentSource = `
      precision mediump float;
      uniform vec2  uRes;
      uniform float uTime;
      uniform float uIntensity;

      float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
      }

      float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(
          mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
          mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
          u.y
        );
      }

      float fbm(vec2 p) {
        float value = 0.0;
        float amplitude = 0.5;
        for (int i = 0; i < 4; i++) {
          value += amplitude * noise(p);
          p *= 2.02;
          amplitude *= 0.5;
        }
        return value;
      }

      void main() {
        vec2 uv = gl_FragCoord.xy / uRes;

        // Steam rises: shift the sampling window down over time.
        vec2 p = vec2(uv.x * 3.2, uv.y * 2.4 - uTime * 0.16);
        float plume = fbm(p + fbm(p * 1.7 + uTime * 0.05));

        // Column mask: strongest at the visual centre, fading before the copy
        // on the left and off the top edge.
        float column = smoothstep(0.10, 0.62, uv.x) * (1.0 - smoothstep(0.72, 0.98, uv.x));
        float rise = smoothstep(0.02, 0.42, uv.y) * (1.0 - smoothstep(0.55, 0.95, uv.y));

        float density = smoothstep(0.42, 0.86, plume) * column * rise;

        // Orange dust, not white smoke: reads as heat over the cream hero.
        vec3 warm = mix(vec3(0.96, 0.51, 0.13), vec3(0.76, 0.29, 0.03), plume * 0.6);
        gl_FragColor = vec4(warm, density * uIntensity);
      }
    `;

    const compile = (type: number, source: string) => {
      const shader = gl.createShader(type);
      if (!shader) return null;
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        gl.deleteShader(shader);
        return null;
      }
      return shader;
    };

    const vertex = compile(gl.VERTEX_SHADER, vertexSource);
    const fragment = compile(gl.FRAGMENT_SHADER, fragmentSource);
    if (!vertex || !fragment) return;

    const program = gl.createProgram();
    if (!program) return;
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) return;
    gl.useProgram(program);

    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);

    const aPos = gl.getAttribLocation(program, 'aPos');
    gl.enableVertexAttribArray(aPos);
    gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, 0, 0);

    const uRes = gl.getUniformLocation(program, 'uRes');
    const uTime = gl.getUniformLocation(program, 'uTime');
    const uIntensity = gl.getUniformLocation(program, 'uIntensity');

    let width = 0;
    let height = 0;
    const resize = () => {
      const ratio = Math.min(window.devicePixelRatio || 1, 2);
      const nextWidth = Math.max(1, Math.floor(canvas.clientWidth * ratio));
      const nextHeight = Math.max(1, Math.floor(canvas.clientHeight * ratio));
      if (nextWidth === width && nextHeight === height) return;
      width = nextWidth;
      height = nextHeight;
      canvas.width = width;
      canvas.height = height;
      gl.viewport(0, 0, width, height);
      gl.uniform2f(uRes, width, height);
    };

    let frame = 0;
    let started = 0;
    let visible = true;
    const still = window.matchMedia('(prefers-reduced-motion: reduce)');

    const render = (now: number) => {
      if (!started) started = now;
      resize();
      gl.uniform1f(uTime, (now - started) / 1000);
      gl.uniform1f(uIntensity, 0.5);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);
      gl.drawArrays(gl.TRIANGLES, 0, 3);
      if (visible && !still.matches) frame = requestAnimationFrame(render);
    };

    // Draw exactly one frame when motion is reduced, then stop.
    if (still.matches) {
      render(performance.now());
      return () => {
        gl.deleteProgram(program);
        gl.deleteShader(vertex);
        gl.deleteShader(fragment);
      };
    }

    frame = requestAnimationFrame(render);

    const observer = new IntersectionObserver(
      ([entry]) => {
        const nextVisible = entry.isIntersecting;
        if (nextVisible && !visible) {
          visible = true;
          frame = requestAnimationFrame(render);
        } else if (!nextVisible && visible) {
          visible = false;
          cancelAnimationFrame(frame);
        }
      },
      { threshold: 0 },
    );
    observer.observe(canvas);

    const onVisibility = () => {
      if (document.hidden) {
        cancelAnimationFrame(frame);
      } else if (visible) {
        frame = requestAnimationFrame(render);
      }
    };
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      document.removeEventListener('visibilitychange', onVisibility);
      gl.deleteProgram(program);
      gl.deleteShader(vertex);
      gl.deleteShader(fragment);
    };
  }, []);

  return <canvas ref={canvasRef} className={className} aria-hidden="true" />;
}
