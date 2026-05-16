export default function ModelPage() {
  return (
    <article className="doc-layout">
      <h1>Model</h1>
      <p>
        The demo solves `-k * laplacian(T) + g_cool * (T - T_ambient) = q(x, y)`
        on a fixed 96x96 grid.
      </p>
      <h2>Blocks</h2>
      <ul>
        <li>MatMul Array A</li>
        <li>MatMul Array B</li>
        <li>SRAM / KV Cache</li>
        <li>NoC Spine</li>
        <li>SerDes / IO</li>
        <li>Control</li>
      </ul>
      <h2>Controls</h2>
      <p>
        Workload phase, power scale, cooling preset, and floorplan mode are the
        only interactive controls.
      </p>
    </article>
  );
}
