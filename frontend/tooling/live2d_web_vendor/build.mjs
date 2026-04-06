// IIFE bundle for web/shizuki_live2d.js (MIT + bundled deps). live2dcubismcore.min.js is Live2D-licensed (loaded separately in HTML).
import * as esbuild from "esbuild";
import { mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const outFile = join(
  __dirname,
  "../../assets/Shizuki_App_Model/web/shizuki_live2d.js",
);

await mkdir(dirname(outFile), { recursive: true });

await esbuild.build({
  entryPoints: [join(__dirname, "app.mjs")],
  bundle: true,
  format: "iife",
  outfile: outFile,
  platform: "browser",
  legalComments: "none",
});

console.log("Wrote", outFile);
