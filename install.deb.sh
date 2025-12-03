# starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
mkdir -p ~/.config
wget 'https://raw.githubusercontent.com/char-46/char-46/refs/heads/master/starship.toml' -O ~/.config/starship.toml
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# TODO: fnm conda...
