# Keep the free VLESS outbounds. Rebuild provider groups so that they do not
# reference removed (Premium / Legend) nodes.
(.outbounds // []) as $all
| ($all | map(select(
    .type == "vless"
    and (.tag | type == "string")
    and (.tag | contains("🔒") | not)
  ))) as $nodes
| if ($nodes | length) == 0 then
    error("HiroVPN: no free VLESS servers found")
  elif (($nodes | map(.tag) | unique | length) != ($nodes | length)) then
    error("HiroVPN: duplicate outbound tags")
  else
    ($all | map(select(.type == "selector" and .tag == "proxy")) | .[0]
      // {type: "selector", tag: "proxy"}) as $selector
    | ($all | map(select(.type == "urltest" and .tag == "auto")) | .[0]
      // {type: "urltest", tag: "auto", url: "https://www.gstatic.com/generate_204", interval: "10m"}) as $auto
    | {
        outbounds: (
          [
            ($selector | .outbounds = (["auto"] + ($nodes | map(.tag))) | .default = "auto"),
            ($auto | .outbounds = ($nodes | map(.tag)))
          ] + $nodes
        )
      }
  end
