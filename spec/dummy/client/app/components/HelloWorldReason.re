type state = {name: string};

type action =
  | UpdateName(string);

let component = ReasonReact.reducerComponent(__MODULE__);

let make = (~name: string, _) => {
  ...component,
  initialState: () => {name: name},
  reducer: (action, _state) =>
    switch (action) {
    | UpdateName(name) => ReasonReact.Update({name: name})
    },
  render: ({state, send}) => <div> <hr /> <form> <input id="name" value={state.name} /> </form> </div>,
};
