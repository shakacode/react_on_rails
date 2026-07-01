import React, { useState } from 'react';

interface HelloWorldProps {
  name: string;
}

const HelloWorld: React.FC<HelloWorldProps> = (props) => {
  const [name, setName] = useState(props.name);

  return (
    <section className="mx-auto max-w-xl rounded-lg border border-slate-200 bg-white p-6 text-slate-900 shadow-sm">
      <p className="text-sm font-semibold uppercase text-sky-600">React on Rails + Tailwind CSS</p>
      <h3 className="mt-2 text-2xl font-bold">Hello, {name}!</h3>
      <p className="mt-3 text-sm leading-6 text-slate-600">
        This component is server-rendered by Rails and styled by Tailwind CSS v4.
      </p>
      <form className="mt-5">
        <label className="block text-sm font-medium text-slate-700" htmlFor="name">
          Say hello to:
          <input
            id="name"
            className="mt-2 w-full rounded-md border border-slate-300 px-3 py-2 shadow-sm focus:border-sky-500 focus:outline-hidden focus:ring-2 focus:ring-sky-200"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </label>
      </form>
    </section>
  );
};

export default HelloWorld;
