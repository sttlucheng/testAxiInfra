# AxiNarrowToWide

Verification environment for the 128-bit to 256-bit AXI width converter.

## Smoke Flow

```bash
source /nfs/home/yanglucheng/tools/verilua/v3.4.0/verilua.sh
xmake AxiNarrowToWideTop -P .
TC=000 SEED=1 xmake run -P . TestAxiNarrowToWide
```

Set `DUMP=1` to generate a waveform:

```bash
TC=000 SEED=1 DUMP=1 xmake run -P . TestAxiNarrowToWide
```

The smoke test writes the low and high 128-bit lanes of one 256-bit memory
word, then reads both lanes back. The scoreboard checks AXI address and
response passthrough, write-data replication, write-strobe lane selection,
read-data lane extraction, and end-of-test queue drain.

## Test-Point Documents

```bash
F=./ut/AxiNarrowToWide/test_points/main.lua xmake run -P . run_zj_docs
```

The generated Markdown and HTML files are written under `build/`.
