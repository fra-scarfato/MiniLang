let enable_logging = ref false
let set_logging b = enable_logging := b

let log_message prefix msg =
  if !enable_logging then Printf.printf "%s %s\n" prefix msg else ()
