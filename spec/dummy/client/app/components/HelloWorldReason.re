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
  render: ({state, send}) =>
    <div>
      <h3> {"Hello, " ++ state.name ++ "!" |> ReasonReact.stringToElement} </h3>
      <hr />
      <form>
        <label htmlFor="name"> {"Say hello to:" |> ReasonReact.stringToElement} </label>
        <input
          id="name"
          _type="text"
          value={state.name}
          onChange={event => UpdateName(event |> Utils.eventTargetValue) |> send}
        />
      </form>
    </div>,
};
