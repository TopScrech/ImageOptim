const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtempSync, writeFileSync, readFileSync, rmSync, existsSync } = require('node:fs');
const { tmpdir } = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const fixture = `<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
<!-- removable comment --><title>Accessible icon</title>
<defs><linearGradient id="paint"><stop offset="0" stop-color="red"/><stop offset="1" stop-color="blue"/></linearGradient></defs>
<rect x="10" y="10" width="80" height="80" fill="url(#paint)"/>
</svg>`;

for (const entry of ['index.js', 'build/svgo.js']) {
    for (const lossy of ['0', '1']) {
        test(`${entry} optimizes SVG in mode ${lossy}`, () => {
            const directory = mkdtempSync(path.join(tmpdir(), 'imageoptim-svgo-'));
            try {
                const input = path.join(directory, 'input.svg');
                const output = path.join(directory, 'output.svg');
                writeFileSync(input, fixture);
                const result = spawnSync(process.execPath, [path.join(__dirname, entry), lossy, input, output], { encoding: 'utf8' });
                assert.equal(result.status, 0, result.stderr);
                assert.equal(result.stderr, '');
                const svg = readFileSync(output, 'utf8');
                assert.match(svg, /<svg/);
                assert.doesNotMatch(svg, /removable comment/);
                assert.ok(svg.length < fixture.length);
                assert.match(svg, /linearGradient/);
                const reference = svg.match(/url\(#([^)]*)\)/)[1];
                assert.ok(svg.includes(`id="${reference}"`), 'Gradient reference remains valid');
                if (lossy === '0') {
                    assert.match(svg, /Accessible icon/);
                    assert.match(svg, /viewBox="0 0 100 100"/);
                    assert.match(svg, /xmlns="http:\/\/www.w3.org\/2000\/svg"/);
                }
            } finally {
                rmSync(directory, { recursive: true, force: true });
            }
        });
    }
    test(`${entry} rejects malformed input without creating output`, () => {
        const directory = mkdtempSync(path.join(tmpdir(), 'imageoptim-svgo-'));
        try {
            const input = path.join(directory, 'input.svg');
            const output = path.join(directory, 'output.svg');
            writeFileSync(input, '<svg><broken></svg>');
            const result = spawnSync(process.execPath, [path.join(__dirname, entry), '0', input, output], { encoding: 'utf8' });
            assert.notEqual(result.status, 0);
            assert.equal(existsSync(output), false);
        } finally {
            rmSync(directory, { recursive: true, force: true });
        }
    });
}
