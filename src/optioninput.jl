function dropdown(::WidgetTheme, options, o = nothing; postprocess = identity, kwargs...)
    extra_attr = Dict(kwargs)
    (o == nothing) && (o = get(extra_attr, :multiple, false) ? String[] : "")
    (o isa Observable) || (o = Observable(o))
    args = [dom"option"(opt) for opt in options]
    s = gensym()
    attrDict = merge(
        Dict(Symbol("v-model") => "value"),
        extra_attr
    )
    template = Node(:select, args..., attributes = attrDict) |> postprocess
    ui = vue(template, ["value"=>o]);
    primary_obs!(ui, "value")
    slap_design!(ui)
end

#TODO: check interactnext API and match it!
function radiobuttons(T::WidgetTheme, options;
    postprocess = identity, kwargs...)

    value = Observable{eltype(options)}(options[1])
    s = gensym()
    btns = [(dom"input[name = $s, type=radio, v-model=value, value=$option]"(),
        dom"label"(option), dom"br"()) for option in options]

    template = dom"form"(
        Iterators.flatten(btns)...
    )
    ui = vue(template, ["value" => value])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function togglebuttons(T::WidgetTheme, options::Associative; tag = :button, class = "interact-widget", outer = dom"div",
    postprocess = identity, activeclass = "active", kwargs...)

    jfunc = js"""function (ev, num){
        this.index = num;
        return this.value = ev;
    }
    """

    value = Observable("")

    btns = [Node(tag,
                 label,
                 attributes=Dict("key" => idx,
                                 "v-on:click"=>"changeValue('$val', $idx)",
                                 "v-bind:class" => "['$class', {'$activeclass' : index == $idx}]")
                 ) for (idx, (label, val)) in enumerate(options)]

    template = outer(
        btns...
    )
    ui = vue(template, ["value" => value, "index" => Observable(0)], methods = Dict(:changeValue => jfunc))
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function togglebuttons(T::WidgetTheme, vals; kwargs...)
    togglebuttons(T::WidgetTheme, OrderedDict(zip(string.(vals), vals)); kwargs...)
end

function tabs(T::WidgetTheme, options::Associative; tag = :li, kwargs...)
    togglebuttons(T::WidgetTheme, options; tag = tag, kwargs...)
end

function tabs(T::WidgetTheme, vals; kwargs...)
    tabs(T::WidgetTheme, OrderedDict(zip(vals, vals)); kwargs...)
end

function mask(options, values; key=Observable(""), display = "block")
    s = string(gensym())
    onjs(key, js"""
        function (k) {
            var options = document.getElementById($s).childNodes;
            for (var i=0; i < options.length; i++) {
                options[i].style.display = (options[i].getAttribute('key') == k) ? $display : 'none';
            }
        }
    """)

    dom"div[id=$s]"(
        (dom"div[key=$option, style=display:none;]"(value) for (option, value) in zip(options, values))...
    )
end
