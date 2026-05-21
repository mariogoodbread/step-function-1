const esbuild = require("esbuild");

const lambdas = ["invoke", "compensate"];

for (const name of lambdas) {
  esbuild.buildSync({
    entryPoints: [`src/${name}/index.ts`],
    outfile: `dist/${name}/index.js`,
    bundle: true,
    platform: "node",
    target: "node22",
    format: "cjs",

    sourcemap: "inline",
    sourcesContent: true,
    keepNames: true,
  });
}