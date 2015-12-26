import test from 'blue-tape';

test('test something start from here:', (outerTest) => {
  outerTest.plan(2);

  outerTest.equal(typeof Date.now, 'function');
  const start = Date.now();
  return (
    setTimeout((innerTest) => {
      innerTest.equal(Date.now() - start, 100);
    }, 100)
  );
});
