// The compiled JavaScript will always extract your props passed to the compiled file from Props, where Props
// is the same hash passed to react_component method on the view. Log the Props in the compiled JS
// and make sure the props passed to the component below match the shape of the prop passed on the view.

@react.component
let default = (~helloWorldData: {..}) => {
  let (nameState, setNameState) = React.useState(_ => helloWorldData["name"])
  <div>
    <h3> {("Hello from ReScript, " ++ nameState ++ ` 🤙`)->React.string} </h3>
    <hr />
    <form>
      <label htmlFor="name">
        {"Say hello to: "->React.string}
        <input
          id="name"
          type_="text"
          value={nameState}
          onChange={e => setNameState(ReactEvent.Form.currentTarget(e)["value"])}
        />
      </label>
    </form>
  </div>
}
