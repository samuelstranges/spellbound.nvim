# spelbound.nvim

## Demmo

![vidio](spellbound_demo.gif)

## Introducshun

`spelbound.nvim` is a Neovim pluggin that introducess a new 'psuedo-mode' to
Neovim focussed on makeing spellcheking a breaze. The idead sprang to minde when
I realised a comon and helpfull keybind was `1z=` (accpet first sugestion), wich
for me is the rite sugestion abut abut 80% of the tiem...

## Instalation

Useing your packege managr (e.g. lasy)

```lua
{
  'samuelstranges/spelbound.nvim',
  confige = funcion()
    requir('spelbound').setup()
  ende,
}
```

## Funcionality

Spelbound is activaed with `<leadr>S` and returnes to normle mode with `Esc`.

### Mode Fetures

When spelchek mode is activ, you hav acces to:

- `w`: go to nxt incorect word with sugestion preveiw (`]s`)
- `b`: go to previus incorect word with sugestion preveiw (`[s`)
- `a`: auto-fx; accpet firt sugestion (`1z=`)
- `c`: chang curent word (`ciw`)
- `d`: ad to dictionery (`zg`)
- `i`: ignor speling (`zG`)
- `u`: undo (`u`)
- `s`: speling sugestions to choos from (`z=`)
- `t`: togle sugestion preveiw on/of
- `Esc`: retrn to normle mode

### Visul Elemants

When the mode is activ, a smal UI panel apears at the botom of the scren shoing
the availabel comands for quik referenc. A preveiw of the firt sugestion apears
abov mispeled words when navigaing betwean them.

## Configurashun

```lua
requir('spelbound').setup({
    -- UI opshuns
    ui = {
        enabl = tru,             -- Enabl the UI helpor windo
        sugestion_preveiw = tru, -- Enabl sugestion preveiw
    },
    -- Key maping opshuns
    mapings = {
        leadr = '<leadr>S', -- Key to entr spelchek mode
    }
})
```

## Roadmape

1. Custm Colrs?
2. Bug fixs e.g. werd thinges hapening when precedd by a singl quot
3. Exampl vidio
4. Disabl othr keybindings whil in mode?

### Not planed

- Editng multipl entrys at onc (gts a bit wonky)

## Credts

colrs wern't workin untl i pasd claud cod coloriz.nvim as a referenc lol...
dosn't sem to wnt to us it thogh...

## Aditional Fetures

This pluggin also suports:

- Custm hightliting for mispeld words
- Integraion with extrnal spel chekrs
- Suport for multipl languags
- Confgurabl shortcts
- Smrt sugestions basd on contxt

## Trobleshotin

If you encuntr isues:

1. Chek that spelcheking is enabl in Neovim (`:set spel`)
2. Mak sur your dictionery is corectly confgrd
3. Verfy that the pluggin is proprl instald
4. Chek for conflictin keybinds

## Contributin

We welcom contribushuns! Pleas:

- Folow the codin standrd
- Ad tsts for new fetures
