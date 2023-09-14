__gpt__last_result=""

function gpt() {
  if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY not set"
    return 1
  fi

  prompt_q="$@"

  if [ -z "$prompt_q" ]; then
    vared -p 'Q: ' -c prompt_q
  fi

  if [ -z "$prompt_q" ]; then
    echo "Error: missing prompt"
    return 1
  fi

  echo "$(cat <<EOF
I am a command line translation tool for $(uname) OS. Ask me what you want to do and I will tell you how to do it using a unix command.

Q: copy a file
cp filename.txt destination_filename.txt

Q: duplicate a folder
cp -a source_folder/ destination_folder/

Q: convert a .heic file to jpg
convert source.heic destination.jpg

Q: navigate to my desktop
cd ~/Desktop/

Q: decompress .tar.gz
tar -xvf filename.tar.gz

Q: download a file from the internet
curl -O https://example.com/file.txt

Q: get the source of a webpage
curl -s http://www.example.com/

Q: convert a .mov to .mp4
ffmpeg -i source.mov -vcodec h264 -acodec mp2 destination.mp4

Q: say hello world
echo "hello world"

Q: what does the p stand for in 'cp -Rp'?
The 'p' stands for 'preserve' and it preserves the original file permissions when copying.

Q: how do you add a comment to a shell script?
To add a comment make sure the line starts with a #

Q: how do I go to the first line using vim
The command gg or :1 will go to the first line

Q: what programs are running
ps -ax

Q: ${prompt_q}
EOF
)" | \
  jq -Rs '{"model": "gpt-4", "messages": [{"role": "user", "content": .}], "temperature": 0, "max_tokens": 512}' | \
  curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_API_KEY" -d @- | \
  jq '.choices[0].text' -rc | \
  read -d '' __gpt__last_result

  echo "$__gpt__last_result"
}

function gpt-zle() {
  setopt localoptions shwordsplit
  context=("${(z)BUFFER}")
  if [ -z "$context" ]; then
    BUFFER="${__gpt__last_result}"
    CURSOR=$#BUFFER
    return
  fi
  if [ -z "$context" ]; then
    echo "Error: missing prompt"
    return 1
  fi
  BUFFER="$(gpt "${context[@]}")"
  CURSOR=$#BUFFER
}

zle -N gpt-zle
bindkey '^g' gpt-zle
