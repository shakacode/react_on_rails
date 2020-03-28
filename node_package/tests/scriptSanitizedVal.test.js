import scriptSanitizedVal from '../src/scriptSanitizedVal';

describe('scriptSanitizedVal', () => {
  expect.assertions(5);
  it('returns no </script if spaces, uppercase 1', () => {
    expect.assertions(1);
    const input = '[SERVER] This is a script:"</div>"</script> <script>alert(\'WTF\')</  SCRIPT >';
    const actual = scriptSanitizedVal(input);
    const expected = '[SERVER] This is a script:"</div>"(/script> <script>alert(\'WTF\')(/script >';
    expect(actual).toEqual(expected);
  });

  it('returns no </script> 2', () => {
    expect.assertions(1);
    const input = 'Script2:"</div>"</script xx> <script>alert(\'WTF2\')</script xx>';
    const actual = scriptSanitizedVal(input);
    const expected = 'Script2:"</div>"(/script xx> <script>alert(\'WTF2\')(/script xx>';
    expect(actual).toEqual(expected);
  });

  it('returns no </script> 3', () => {
    expect.assertions(1);
    const input = 'Script3:"</div>"</  SCRIPT xx> <script>alert(\'WTF3\')</script xx>';
    const actual = scriptSanitizedVal(input);
    const expected = 'Script3:"</div>"(/script xx> <script>alert(\'WTF3\')(/script xx>';
    expect(actual).toEqual(expected);
  });

  it('returns no </script> 4', () => {
    expect.assertions(1);
    const input = 'Script4"</div>"</script <script>alert(\'WTF4\')</script>';
    const actual = scriptSanitizedVal(input);
    const expected = 'Script4"</div>"(/script <script>alert(\'WTF4\')(/script>';
    expect(actual).toEqual(expected);
  });

  it('returns no </script> 5', () => {
    expect.assertions(1);
    const input = 'Script5:"</div>"</ script> <script>alert(\'WTF5\')</script>';
    const actual = scriptSanitizedVal(input);
    const expected = 'Script5:"</div>"(/script> <script>alert(\'WTF5\')(/script>';
    expect(actual).toEqual(expected);
  })
})
