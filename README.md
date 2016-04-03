# vim-cloud-buffer

CloudBuffer is a plugin developed to store and retrieve buffers in a [MongoDB Simple Http Rest endpoint][mongorest].


Highly inspired by [gist-vim][gist-vim], it's indented to be used as a mean to centralise "work in progress" documents in the cloud.
If you just want to instantly share code, notes, and snippets, [gist-vim][gist-vim] will suit you best.

## Features

* Lists your most recently updated buffers at the top giving you an immediate context of what you are working on
* Remembers buffer `filetype` and jumps to the last modified position in the buffer upon retrieval
* Prevents losing buffer contents by accident by issuing soft deletes
* Allows you to search historical buffers using regular expressions

Let me show you a glimpse:

![vim-cloud-buffer](https://cloud.githubusercontent.com/assets/24221/11484718/e7a19738-97af-11e5-89fa-30a047f575df.gif)

## Usage

Save current buffer remotely:

```viml
:CloudBuffer -s
```

List your remote buffers:

```viml
:CloudBuffer
:CloudBuffer -l
" add bang(!) to include deleted buffers
:CloudBuffer!
:CloudBuffer! -l
" Hit enter to retrieve a buffer in the list
```

`:CloudBuffer` also retrieves a specific buffer when issued from a line
containing an embedded buffer id with the following format:

`BufferId:56403ab4e4b09256a23f49d8`

List buffers matching a criteria:

```viml
:CloudBuffer -re regexp
" add bang(!) to include deleted buffers
:CloudBuffer! -re regexp
```

Delete a buffer

```viml
:CloudBuffer -d
" add bang(!) to remove a buffer permanently
:CloudBuffer! -d
```

## Requirements

## Installation

### Plugin managers

The most common plugin managers include [vim-plug][vim-plug],
[NeoBundle][neobundle], [Vundle][vundle] and [pathogen.vim][pathogen].

With pathogen.vim, just clone this repository inside `~/.vim/bundle`:

```bash
git clone https://github.com/jbgutierrez/vim-cloud-buffer.git ~/.vim/bundle/vim-cloud-buffer
git clone https://github.com/mattn/webapi-vim.git ~/.vim/bundle/webapi-vim
```

With the other plugin managers, just follow the instructions on the homepage of each plugin. In general, you just have to add a line to your `~/.vimrc`:

```viml
" vim-plug
Plug 'jbgutierrez/vim-cloud-buffer'
Plug 'mattn/webapi-vim'
" NeoBundle
NeoBundle 'jbgutierrez/vim-cloud-buffer'
NeoBundle 'mattn/webapi-vim'
" Vundle
Plugin 'jbgutierrez/vim-cloud-buffer'
Plugin 'mattn/webapi-vim'
```

### Manual installation

Copy the contents of each directory in the respective directories inside
`~/.vim`.

You need to install webapi-vim also:

  http://www.vim.org/scripts/script.php?script_id=4019

If you want to use latest one:

  https://github.com/mattn/webapi-vim

# Setup

This plugin has been tested using `mongolab` hosting service. Sign up for a 500Mb free account and [follow these steps][mongolabs] if you lack a [MongoDB Simple Http Rest endpoint][mongorest].

Just declare the following two variables in your `.vimrc`

```viml
let g:vim_cloud_buffer_url = "https://api.mongolab.com/api/1/databases/vim-cloud-buffer/collections/buffers"
let g:vim_cloud_buffer_api_key = "SECRET"
```

## Bugs

Please report any bugs you may find on the GitHub [issue tracker](http://github.com/jbgutierrez/vim-cloud-buffer/issues).

## Contributing

Think you can make CloudBuffer better? Great!, contributions are always welcome.

Fork the [project](http://github.com/jbgutierrez/vim-cloud-buffer) on GitHub and send a pull request.

## License

CloudBuffer is licensed under the MIT license.
See http://opensource.org/licenses/MIT

Happy hacking!

> **Note:**
> Did you find this plugin useful? Please star it and
> [share](https://twitter.com/intent/tweet?text=%23vim-cloud-buffer%20-%20save%20your%20buffers%20remotely%20with%20this%20%23vim%20plugin%20https%3A%2F%2Fgithub.com%2Fjbgutierrez%2Fvim-cloud-buffer&source=webclient)
> with others.

[vim-plug]: https://github.com/junegunn/vim-plug
[vundle]: https://github.com/gmarik/Vundle.vim
[neobundle]: https://github.com/Shougo/neobundle.vim
[pathogen]: https://github.com/tpope/vim-pathogen
[gist-vim]: https://github.com/mattn/gist-vim
[mongorest]: https://docs.mongodb.org/ecosystem/tools/http-interfaces/#rest-interface
[mongolabs]: http://docs.mongolab.com/data-api/#authentication
