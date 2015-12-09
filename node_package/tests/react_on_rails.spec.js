import test from 'blue-tape';

test('test something start from here:', (t) => {
  t.plan(2);

  t.equal(typeof Date.now, 'function');
  const start = Date.now();
  return (
    setTimeout((t) => {
      t.equal(Date.now() - start, 100);
    }, 100)
  );
});