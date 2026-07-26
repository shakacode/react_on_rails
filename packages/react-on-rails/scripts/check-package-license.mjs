import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const expectedOssMitLicense = `Copyright (c) 2017, 2018 Justin Gordon and ShakaCode
Copyright (c) 2015–2025 ShakaCode, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
`;

const readPackedFile = (tarballPath, packedPath) =>
  execFileSync('tar', ['-xOzf', tarballPath, packedPath], { encoding: 'utf8' });

const temporaryDirectory = mkdtempSync(join(tmpdir(), 'react-on-rails-license-'));

try {
  execFileSync('pnpm', ['pack', '--pack-destination', temporaryDirectory], { stdio: 'inherit' });

  const [tarball] = readdirSync(temporaryDirectory).filter((file) => file.endsWith('.tgz'));
  assert.ok(tarball, 'pnpm pack should produce a tarball');

  const tarballPath = join(temporaryDirectory, tarball);
  const packedPackage = JSON.parse(readPackedFile(tarballPath, 'package/package.json'));
  const packedLicense = readPackedFile(tarballPath, 'package/LICENSE.md');

  assert.equal(packedPackage.license, 'MIT');
  assert.equal(packedLicense, expectedOssMitLicense);
  assert.doesNotMatch(packedLicense, /React on Rails Pro|subscription|commercial/i);
} finally {
  rmSync(temporaryDirectory, { force: true, recursive: true });
}
