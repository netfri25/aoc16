use std/log

const SESSION_PATH: path = "~/.adventofcode.session"

def get-session [
  session?: string
]: nothing -> string {
  $session | default { open ($SESSION_PATH | path expand -s) } | str trim
}

def make-url [
  year: int
  day: int
  target?: string
  --params: record = {}
]: nothing -> string {
  let format_vars = {
    year: $year,
    day: $day,
    target: $target
  }

  {
    "scheme": "https"
    "host": "adventofcode.com"
    "path": ($"/($year)/day/($day)/($target)" | str trim -r -c "/")
    "params": $params
  } | url join
}

def make-headers [
  session?: string
  --extra-headers: record = {}
]: nothing -> record {
  $extra_headers | merge { cookie: $"session=(get-session $session)" }
}

export def download [
  year: int
  day: int
  --force (-f)
  --session (-s): string
  --puzzle-path (-p): path = "./puzzle.md"
  --input-path (-i): path = "./input"
]: nothing -> nothing {
  download puzzle $year $day --session $session | save -f $puzzle_path

  if $force or not ($input_path | path exists) {
    download input $year $day --session $session | save -f $input_path
  }
}

export def "download puzzle" [
  year: int
  day: int
  --session (-s): string
]: nothing -> string {
  let url = make-url $year $day
  let headers = make-headers $session
  log info $"download puzzle ($url)"

  http get $url --headers $headers
  | parse --regex "(?i)(?s)<main>(?P<main>.*)</main>"
  | get main.0
  | str trim
  | html2text
}

export def "download input" [
  year: int
  day: int
  --session (-s): string
]: nothing -> string {
  let url = make-url $year $day "input"
  let headers = make-headers $session
  log info $"download input ($url)"

  http get $url --headers $headers
}

export def "submit" [
  year: int
  day: int
  part: int
  --session (-s): string
]: any -> nothing {
  let url = make-url $year $day "answer"
  let headers = make-headers $session --extra-headers {"content-type": "application/x-www-form-urlencoded"}

  log info $"submit answer to ($url)"
  log debug $"answer: ($in)"

  $"level=($part)&answer=($in)"
  | http post $url --headers $headers
  | parse --regex "(?i)(?s)<main>(?P<main>.*)</main>"
  | get main.0
  | str trim
  | html2text
}
