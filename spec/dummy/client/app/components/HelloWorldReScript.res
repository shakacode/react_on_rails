// The compiled JavaScript will always extract your props passed to make from Props, where Props
// is the same hash passed to react_component method on the view. Log the Props in the compiled JS
// And make sure the props passed to make match the shape of the prop passed on the view.

@react.component
let make = (~helloWorldData: {..}) => {
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
