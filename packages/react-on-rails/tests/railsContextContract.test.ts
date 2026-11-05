import { readFileSync } from 'fs';
import { resolve } from 'path';
import * as ts from 'typescript';

it('keeps RailsContext type keys aligned with the shared Ruby helper contract', () => {
  const contract = JSON.parse(
    readFileSync(resolve(__dirname, 'fixtures/rails-context-keys.json'), 'utf8'),
  ) as { rubyKeys: string[]; serverOnlyKeys: string[] };
  const filename = resolve(__dirname, '../src/types/index.ts');
  const source = ts.createSourceFile(filename, readFileSync(filename, 'utf8'), ts.ScriptTarget.Latest, true);
  const declaration = source.statements.find(
    (statement): statement is ts.TypeAliasDeclaration =>
      ts.isTypeAliasDeclaration(statement) && statement.name.text === 'RailsContext',
  );
  expect(declaration).toBeDefined();
  const keys = new Set<string>();
  const visit = (node: ts.TypeNode) => {
    if (ts.isTypeLiteralNode(node)) {
      node.members.forEach((member) => {
        if (
          (ts.isPropertySignature(member) || ts.isMethodSignature(member)) &&
          (ts.isIdentifier(member.name) || ts.isStringLiteral(member.name))
        ) {
          keys.add(member.name.text);
        } else {
          throw new Error(`Unsupported RailsContext member: ${member.getText(source)}`);
        }
      });
    } else if (ts.isUnionTypeNode(node) || ts.isIntersectionTypeNode(node)) {
      node.types.forEach(visit);
    } else if (ts.isParenthesizedTypeNode(node)) {
      visit(node.type);
    } else {
      throw new Error(`Unsupported RailsContext type: ${node.getText(source)}`);
    }
  };
  if (declaration) visit(declaration.type);

  // Pro/JavaScript adds server-only callbacks and manifest fields after Ruby builds its context.
  expect([...keys].sort()).toEqual([...contract.rubyKeys, ...contract.serverOnlyKeys].sort());
});
