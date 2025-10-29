jest.mock('react-dom/server', () => {
  throw new Error("ReactOnRailsRSC shouldn't import react-dom/server at all");
});

test('import ReactOnRailsRSC', async () => {
  await expect(import('../src/ReactOnRailsRSC.ts')).resolves.toEqual(
    expect.objectContaining({
      default: expect.objectContaining({
        isRSCBundle: true,
      }) as unknown,
    }),
  );
});
