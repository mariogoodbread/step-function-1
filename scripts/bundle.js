const esbuild = require("esbuild");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const lambdas = ["invoke", "compensate"];

for (const name of lambdas) {
  const outdir = path.join("dist", name);
  fs.mkdirSync(outdir, { recursive: true });

  esbuild.buildSync({
    entryPoints: [`src/${name}/index.ts`],
    bundle: true,
    platform: "node",
    target: "node20",
    outfile: `${outdir}/index.js`,
    external: [],
  });

  execSync(`powershell Compress-Archive -Force -Path ${outdir}\\index.js -DestinationPath dist\\${name}.zip`);
  console.log(`Built dist/${name}.zip`);
}
