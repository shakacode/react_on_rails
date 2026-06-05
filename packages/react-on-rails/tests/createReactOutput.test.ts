import * as React from 'react';
import createReactOutput from '../src/createReactOutput.ts';
import type {
  CreateReactOutputResult,
  ReactComponent,
  RegisteredComponent,
  RegisteredComponentValue,
} from '../src/types/index.ts';

type TestProps = {
  message: string;
};

const props: TestProps = {
  message: 'hello',
};

const createRegisteredComponent = (
  name: string,
  component: RegisteredComponentValue,
): RegisteredComponent<RegisteredComponentValue> => ({
  name,
  component,
  renderFunction: false,
  isRenderer: false,
});

const renderOutputFor = (name: string, component: RegisteredComponentValue): CreateReactOutputResult =>
  createReactOutput({
    componentObj: createRegisteredComponent(name, component),
    props,
    domNodeId: 'react-object-component',
  });

const expectReactElement = (value: CreateReactOutputResult): React.ReactElement => {
  if (!React.isValidElement(value)) {
    throw new Error('Expected createReactOutput to return a React element');
  }
  return value;
};

describe('createReactOutput', () => {
  it.each<[string, ReactComponent]>([
    ['memo', React.memo(({ message }: TestProps) => React.createElement('div', null, message))],
    [
      'forwardRef',
      React.forwardRef<HTMLDivElement, TestProps>(({ message }, ref) =>
        React.createElement('div', { ref }, message),
      ),
    ],
    [
      'lazy',
      React.lazy(async () => ({
        default: ({ message }: TestProps) => React.createElement('div', null, message),
      })),
    ],
  ])('creates an element for React.%s object component types', (name, component) => {
    const output = expectReactElement(renderOutputFor(name, component));

    expect(output.type).toBe(component);
    expect(output.props).toEqual(props);
  });

  it('rejects plain object registrations when they are rendered as components', () => {
    const objectModule = {
      hello() {
        return 'world';
      },
    };

    expect(() => renderOutputFor('ObjectModule', objectModule)).toThrow(
      'Registered component "ObjectModule" must be a function, string, or React object component type.',
    );
  });
});
