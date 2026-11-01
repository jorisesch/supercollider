// Render a saved record, optionally through another channel, without changing its recipe.
// Args: "complete track name" [edm|edme|original] [bars] [percussion|chords|bass].
// An optional component adds just that E part to the original EDM. CLI only.
(
var root=thisProcess.nowExecutingPath.dirname,args=thisProcess.argv;
var name=args.at(0),channel=(args.at(1) ? "original").asSymbol,slug,component=args.at(3);
try {
if(name.isNil) {Error("Provide a complete saved track name").throw};
if([\edm,\edme,\original].includes(channel).not) {Error("Unknown render channel").throw};
if(component.notNil) {
    component=component.asSymbol;
    if(channel!=\edme or: {[\percussion,\chords,\bass].includes(component).not}) {
        Error("An isolated component requires edme and percussion, chords or bass").throw;
    };
};
slug=name.toLower.replace(" ","-");
if("^[a-z-]+$".matchRegexp(slug).not) {Error("Invalid track name").throw};
~djRenderRecipe=name;
~djRenderChannel=if(channel==\original) {nil} {channel};
~djRenderBars=(args.at(2) ? "40").asInteger.clip(8,256);
~djRenderName=slug ++ "-" ++ if(channel==\edme) {"edm-e"} {channel.asString};
~djRenderComponent=component;
if(component.notNil) {~djRenderName=~djRenderName ++ "-" ++ component};
(root +/+ "render.scd").load;
} {|error|error.reportError;1.exit};
)
