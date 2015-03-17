" Search4Gvim
" search and replace functions for GVim
" enhanced dialogs with Perl-Gtk2
" Copyright (C) 2010  Oleg V. Motygin
" ver. 0.1.16
" 17/06/2010
" License:
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 3 of the License, or
" (at your option) any later version. [ http://www.gnu.org/licenses/gpl.html ]

let g:isPerl_Gtk2=0

if has('perl')
  function CheckModules()
     perl << EOF
      BEGIN {
         eval "require Gtk2";
         unless ($@) {
            VIM::DoCommand('let g:isPerl_Gtk2=1');
         }
      };
EOF
  endfunction
  call CheckModules()
endif

if g:isPerl_Gtk2==1

" option: case sensitive? (1=yes, 0=no)
if !exists("g:SEARCH4GVIM_FCASE")
	let g:SEARCH4GVIM_FCASE = 0
endif

" option: regular expressions? (1=yes, 0=no)
if !exists("g:SEARCH4GVIM_FREGEXP")
	let g:SEARCH4GVIM_FREGEXP = 0
endif

" option: prompt on replace? (1=yes, 0=no)
if !exists("g:SEARCH4GVIM_PROMPT")
	let g:SEARCH4GVIM_PROMPT = 1
endif

" history of replaces
if !exists("g:SEARCH4GVIM_REPL")
	let g:SEARCH4GVIM_REPL = ""
endif

let g:splititems=nr2char(0x21b4) . nr2char(0x21b4) . nr2char(0x21b4)

let g:SEARCH4GVIM_REPLLST = split(g:SEARCH4GVIM_REPL,g:splititems)

if len(g:SEARCH4GVIM_REPLLST)>15
   call remove(g:SEARCH4GVIM_REPLLST,1,len(g:SEARCH4GVIM_REPLLST)-15)
   let g:SEARCH4GVIM_REPL = g:SEARCH4GVIM_REPLLST[0]
   let i = 1
   while (i < len(g:SEARCH4GVIM_REPLLST))
      let g:SEARCH4GVIM_REPL = g:SEARCH4GVIM_REPL . g:splititems . g:SEARCH4GVIM_REPLLST[i]
      let i=i+1
   endwhile
endif

function! MkLnVisible()
	let diff_ln = winline()-&lines/2-g:lnskip4dlg
	if diff_ln < 0
		exe "normal " . (-diff_ln) . "\<C-Y>"
	elseif diff_ln > 0
		exe "normal " . (diff_ln) . "\<C-E>"
	endif
	redraw
endfunction

function! GetVisualSelection()
	let save_a = @a
	silent normal! gv"ay
	let res = @a
	let @a = save_a
	return res
endfunction

function MsearchSavePars()
  let g:smartcase_sav=&smartcase
  let g:wrapscan_sav=&wrapscan
  let g:mymagic = &magic
endfunc

function MsearchSetPars()
  set nosmartcase
  set wrapscan
"  set nomagic
endfunc

function MsearchRestorePars()
  if g:mymagic == "1"
	set magic
"  else
"	set nomagic
  endif
  let &smartcase=g:smartcase_sav
  let &wrapscan=g:wrapscan_sav
endfunc

function FindDown()
  call MsearchSetPars()
  let g:pattern_found=0
  let myfind = g:SEARCH4GVIM_FFIND
  if g:SEARCH4GVIM_FCASE == 1
     set noignorecase
     let ic4match=""
  else
     set ignorecase
     let ic4match="\\c"
  endif
  if g:SEARCH4GVIM_FREGEXP == 1
	let myregexp = ""
	set magic
  else
	let myregexp = "\\V"
"	set nomagic
	let myfind = substitute(myfind, '\\', '\\\\', 'g')
	let myfind = substitute(myfind, '/', '\\/', 'g')
  endif
  if mode() == "v"
    normal v
  endif
  let bnum = search(myregexp . myfind)
  if bnum != 0
    let g:pattern_found=1
    norm v
    call search(myregexp . myfind,"ce")
    norm l
    norm v
 "   highlight FoundPatt gui=reverse
    exe "2match Search /" . ic4match . myregexp . myfind .  "/"
    match Visual /\%V.*\%V/
    call MkLnVisible()
  endif
  call MsearchRestorePars()
endfunc

function FindUp()
  call MsearchSetPars()
  let g:pattern_found=0
  let myfind = g:SEARCH4GVIM_FFIND
  if g:SEARCH4GVIM_FCASE == 1
     set noignorecase
     let ic4match=""
  else
     set ignorecase
     let ic4match="\\c"
  endif
  if g:SEARCH4GVIM_FREGEXP == 1
	let myregexp = ""
	set magic
  else
	let myregexp = "\\V"
"	set nomagic
	let myfind = substitute(myfind, '\\', '\\\\', 'g')
	let myfind = substitute(myfind, '/', '\\/', 'g')
  endif
  if mode() == "v"
    normal v
  endif
  let cur_col = col(".")
  let cur_ln = line(".")
  let bnum = search(myregexp . myfind,"b")
  if bnum != 0
    let beg_col=col(".")
    norm v
    call search(myregexp . myfind,"ce")
    norm l
    norm v
    let end_col=col(".")
    let end_ln=line(".")
    if ((bnum<end_ln)&&(cur_ln<end_ln)&&(cur_ln>bnum))||
       \ ((bnum==end_ln)&&(cur_ln==bnum)&&(cur_col>=beg_col)&&(cur_col<=end_col))||
       \ ((bnum<end_ln)&&(cur_ln==bnum)&&(cur_col>=beg_col))||
       \ ((bnum<end_ln)&&(cur_ln==end_ln)&&(cur_col<=end_col))
      call search(myregexp . myfind,"b")
      let bnum = search(myregexp . myfind,"b")
      if bnum != 0
        norm v
        call search(myregexp . myfind,"ce")
        norm l
        norm v
      endif
    endif
  endif
  if bnum != 0
    let g:pattern_found=1
    call search(myregexp . myfind,"cb")
"    highlight FoundPatt guibg=red
    exe "2match Search /". ic4match . myregexp . myfind .  "/"
    match Visual /\%V.*\%V/
    call MkLnVisible()
  endif
  call MsearchRestorePars()
endfunc

function! Msearch(...)

if (a:0 > 0)&&(a:1=="v")
  let g:SEARCH4GVIM_FSEL = GetVisualSelection()
  let mln = max([2*&tw,2*&wm,100])
  if strlen(g:SEARCH4GVIM_FSEL) > mln
    let g:SEARCH4GVIM_FSEL = strpart(g:SEARCH4GVIM_FSEL,0,mln)
  endif
  if mode() == "v"
    normal v
  endif
else 
  let g:SEARCH4GVIM_FSEL = ""
endif

call MsearchSavePars()

let g:lnskip4dlg=5

perl << EOF

use warnings;
use strict;
use utf8;
use encoding "utf8";
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::Gdk::Keysyms;

# This callback quits the program
sub delete_event
{
  Gtk2->main_quit;
  return FALSE;
}

sub fill_search_history
{ use vars qw($search_entry $models);
  $models->clear;
  my @prevsearches=();
  my $success; my $expr;
  ($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FSEL');
  if (($success==1) && ($expr ne "")) {
    push( @prevsearches, $expr );
  }
  foreach (1..15) {
    ($success,$expr) = VIM::Eval('histget("search",-'. $_ .')');
    if ($expr ne "") {
      push( @prevsearches, $expr );
    }
  }
  foreach (@prevsearches) {
       $models->set ($models->append, 0, $_);
   }
  $search_entry->get_child()->set_text($prevsearches[0]); 
}

sub casetoggle
{
my $success; my $cs;
($success,$cs) = VIM::Eval('g:SEARCH4GVIM_FCASE');
if ($cs==1) {
   VIM::DoCommand('let g:SEARCH4GVIM_FCASE=0'); }
else {
   VIM::DoCommand('let g:SEARCH4GVIM_FCASE=1'); }
}

sub regexptoggle
{
my $success; my $rexp;
($success,$rexp) = VIM::Eval('g:SEARCH4GVIM_FREGEXP');
if ($rexp==1) {
   VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=0'); }
else {
   VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=1'); }
}

sub searchdownup {
  my $dir = $_[0];
  if ($dir ne "up") {$dir="down";}
  use vars qw($search_entry);
  my $success; my $expr; my $s;
  my $search = $search_entry->get_child()->get_text;
  $s = $search; $s =~ s/['"\\\x0]/\\$&/g;
  VIM::DoCommand('let g:SEARCH4GVIM_FFIND="'.$s.'"');
  ($success,$expr) = VIM::Eval('histget("search",-1)');
  if ($expr ne $search) { VIM::DoCommand('call histadd("search","'.$s.'")'); }
  fill_search_history();
  if ($dir eq "down") { VIM::DoCommand('call FindDown()'); }
  else { VIM::DoCommand('call FindUp()'); } 
}

# Create the window
my $window = new Gtk2::Window ( "toplevel" );
$window->set_title("Search");
$window->set_border_width (10);
$window->set_position('center');

$window->set_accept_focus(TRUE);
$window->set_destroy_with_parent(TRUE);
$window->set_keep_above(TRUE);

$window->signal_connect(delete_event => \&delete_event);
$window->signal_connect(destroy => sub { VIM::DoCommand('2match');VIM::DoCommand('match');Gtk2->main_quit; });
$window->signal_connect (key_press_event => sub {
    my ($widget, $event) = @_;
    if ($event->keyval == $Gtk2::Gdk::Keysyms{Escape}) {
       $widget->destroy;
    }
    return 0;
});

my $box0 = Gtk2::VBox->new(FALSE, 3);
my $box1 = Gtk2::HBox->new(FALSE, 0);
my $separator = Gtk2::HSeparator->new;

$window->add($box0);

my $success; my $expr;

our $models = Gtk2::ListStore->new ('Glib::String');
our $search_entry = Gtk2::ComboBoxEntry->new($models, 0);

fill_search_history();

VIM::DoCommand('let g:SEARCH4GVIM_FSEL=""');

$box0->pack_start($search_entry, TRUE, TRUE, 0);

my $casecheck = Gtk2::CheckButton->new_with_label("Case sensitive");
my $regexpcheck = Gtk2::CheckButton->new_with_label("Regular expressions");
my $tooltipcase = Gtk2::Tooltips->new;
my $tooltipregexp = Gtk2::Tooltips->new;
$tooltipcase->set_tip($casecheck, "Case sensitive search");
$tooltipregexp->set_tip($regexpcheck, "Regular expressions in search request");

($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FCASE');
if ($success!=1) { VIM::DoCommand('let g:SEARCH4GVIM_FCASE=1'); $expr = 1; }
if ($expr==1) { $casecheck->set_active(TRUE); }
else { $casecheck->set_active(FALSE); }

($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FREGEXP');
if ($success!=1) { VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=1'); $expr = 1; }
if ($expr==1) {$regexpcheck->set_active(TRUE); }
else {$regexpcheck->set_active(FALSE); }

$casecheck->signal_connect(toggled => \&casetoggle, $window);
$regexpcheck->signal_connect(toggled => \&regexptoggle, $window);

my $buttonDown = Gtk2::Button->new("Search downward");
my $buttonUp = Gtk2::Button->new("Search upward");
my $buttonCancel = Gtk2::Button->new("Cancel");

$buttonDown->signal_connect(clicked => sub { searchdownup("down"); }, $window);
$buttonUp->signal_connect(clicked => sub { searchdownup("up"); }, $window);
$buttonCancel->signal_connect(clicked => sub { VIM::DoCommand('2match');VIM::DoCommand('match');$window->destroy; });

$box1->pack_start($buttonDown, TRUE, TRUE, 0);
$box1->pack_start($buttonUp, TRUE, TRUE, 0);
$box1->pack_start($buttonCancel, TRUE, TRUE, 0);

$box0->pack_start($casecheck, FALSE, FALSE, 0);
$box0->pack_start($regexpcheck, FALSE, FALSE, 0);
$box0->pack_start($separator, FALSE, FALSE, 5);
$box0->pack_start($box1, FALSE, FALSE, 0);

$window->show_all;

Gtk2->main;
0;
EOF

return ""
endfunc

function AllWithoutPrompt(...)
  call MsearchSetPars()
  if (a:0 == 0)||((a:1!="down")&&(a:1!="up"))
    let dir = "down"
  else
    let dir = a:1
  endif
  let myfind = g:SEARCH4GVIM_FFIND
  let myrepl = g:SEARCH4GVIM_RREPL
  if g:SEARCH4GVIM_FCASE == 1
     let mycase = "I"
     set noignorecase
  else
     let mycase = "i"
     set ignorecase
  endif
  if g:SEARCH4GVIM_FREGEXP == 1
	let myregexp = ""
	set magic
  else
      let myregexp = "\\V"
"      set nomagic
      let myfind = substitute(myfind, '\\', '\\\\', 'g')
      let myfind = substitute(myfind, '/', '\\/', 'g')
      let myrepl = substitute(myrepl, '\\', '\\\\', 'g')
      let myrepl = substitute(myrepl, '/', '\\/', 'g')
      let myrepl = substitute(myrepl, '\\n', '\\r', 'g')
  endif
  redir => g:echoed_var
  if dir=="down"
    execute "silent! .,$substitute/" . myregexp . myfind . "/" . myrepl . "/ge" . mycase
  else
    execute "silent! 1,.substitute/" . myregexp . myfind . "/" . myrepl . "/ge" . mycase
  endif
  redir END
  if myfind != histget("search",-1)
    call histdel("search",-1)
  endif
  let pos=match(g:echoed_var, " ")
  if pos > 0
    let g:numfound = strpart(g:echoed_var,1,pos)
    if g:numfound !~ "\\d\\+"
       let g:numfound = -1
    endif
  else
    let g:numfound = 1
  endif
  redraw!
  call MsearchRestorePars()
endfunc

function ReplaceSelected(...)
  call MsearchSetPars()
  let myfind = g:SEARCH4GVIM_FFIND
  let myrepl = g:SEARCH4GVIM_RREPL
  if g:SEARCH4GVIM_FCASE == 1
     let mycase = "I"
     set noignorecase
  else
     let mycase = "i"
     set ignorecase
  endif
  if g:SEARCH4GVIM_FREGEXP == 1
	let myregexp = ""
	set magic
  else
      let myregexp = "\\V"
"      set nomagic
      let myfind = substitute(myfind, '\\', '\\\\', 'g')
      let myfind = substitute(myfind, '/', '\\/', 'g')
      let myrepl = substitute(myrepl, '\\', '\\\\', 'g')
      let myrepl = substitute(myrepl, '/', '\\/', 'g')
      let myrepl = substitute(myrepl, '\\n', '\\r', 'g')
  endif
  norm `<
  let cur_col=virtcol(".")
  let cur_ln=line(".")
  redir => g:echoed_var
  execute "silent! %s/\\%V" . myregexp . myfind . "/" . myrepl . "/e" . mycase
  redir END
  if myfind != histget("search",-1)
    call histdel("search",-1)
  endif
  execute "normal " . cur_ln . "G"
  execute "normal " . cur_col . "|"
  if (a:0 > 0)&&(a:1=="down")
     normal l
  else
     normal h
  endif
  match
  if strlen(g:echoed_var)==0
    let g:numfound=1
  else
    let g:numfound=-1
  endif
  redraw!
  call MsearchRestorePars()
endfunc

function HistRepl_get(...)
   if (a:0 > 0)&&(a:1!=-1)
     let ind = a:1
   else
     let ind = -1
   endif
   if ((ind < 0) && (len(g:SEARCH4GVIM_REPLLST) < -ind)) || ((ind >= 0) && (len(g:SEARCH4GVIM_REPLLST) < ind+1))
     return ""
   else
     return g:SEARCH4GVIM_REPLLST[ind]
  endif
endfunc

function HistRepl_add(...)
   if (a:0 > 0)&&(a:1 != "")
     let patt = a:1
     if len(g:SEARCH4GVIM_REPLLST)>0
       call filter(g:SEARCH4GVIM_REPLLST, 'v:val != "' .  patt . '"')
     endif
     call add(g:SEARCH4GVIM_REPLLST, patt)
     let g:SEARCH4GVIM_REPL = g:SEARCH4GVIM_REPLLST[0]
     let i = 1
     while (i < len(g:SEARCH4GVIM_REPLLST))
        let g:SEARCH4GVIM_REPL = g:SEARCH4GVIM_REPL . g:splititems . g:SEARCH4GVIM_REPLLST[i]
        let i=i+1
     endwhile
  endif
endfunc

function! Mreplace(...)

if (a:0 > 0)&&(a:1=="v")
  let g:SEARCH4GVIM_FSEL = GetVisualSelection()
  let mln = max([2*&tw,2*&wm,100])
  if strlen(g:SEARCH4GVIM_FSEL) > mln
    let g:SEARCH4GVIM_FSEL = strpart(g:SEARCH4GVIM_FSEL,0,mln)
  endif
  if mode() == "v"
    normal v
  endif
else 
  let g:SEARCH4GVIM_FSEL = ""
endif

call MsearchSavePars()

let g:lnskip4dlg=7

perl << EOF

use warnings;
use strict;
use utf8;
use encoding "utf8";
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::Gdk::Keysyms;

# This callback quits the program
sub delete_event
{
	Gtk2->main_quit;
	return FALSE;
}

sub msg
{
  use vars qw($status);
  $status->set_text( $_[0] ); 
}

sub fill_search_repl_history
{ use vars qw($search_entry $replace_entry $models $modelr);
  $models->clear;
  $modelr->clear;
  my @prevsearches=();
  my $success; my $expr;
  ($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FSEL');
  if (($success==1) && ($expr ne "")) {
    push( @prevsearches, $expr );
  }
  foreach (1..15) {
    ($success,$expr) = VIM::Eval('histget("search",-'. $_ .')');
    if ($expr ne "") {
      push( @prevsearches, $expr );
    }
  }
  foreach (@prevsearches) {
       $models->set ($models->append, 0, $_);
   }
  $search_entry->get_child()->set_text($prevsearches[0]); 

  my @prevreplaces=();
  foreach (1..15) {
    ($success,$expr) = VIM::Eval('HistRepl_get(-'. $_ .')');
    if ($expr ne "") {
      push( @prevreplaces, $expr );
    }
  }
  foreach (@prevreplaces) {
       $modelr->set ($modelr->append, 0, $_);
  }
  $replace_entry->get_child()->set_text($prevreplaces[0]); 
}

sub casetoggle
{
  my $success; my $cs;
  msg('');
  ($success,$cs) = VIM::Eval('g:SEARCH4GVIM_FCASE');
  if ($cs==1) { VIM::DoCommand('let g:SEARCH4GVIM_FCASE=0'); }
  else { VIM::DoCommand('let g:SEARCH4GVIM_FCASE=1'); }
}

sub regexptoggle
{
  my $success; my $rexp;
  msg('');
  ($success,$rexp) = VIM::Eval('g:SEARCH4GVIM_FREGEXP');
  if ($rexp==1) { VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=0'); }
  else { VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=1'); }
}

sub prompttoggle
{
  use vars qw($buttonUp $buttonDown);
  my $success; my $prompt;
  msg('');
  ($success,$prompt) = VIM::Eval('g:SEARCH4GVIM_PROMPT');
  if ($prompt==1) {
    VIM::DoCommand('let g:SEARCH4GVIM_PROMPT=0'); 
    $buttonUp->set_label("Replace all upward");
    $buttonDown->set_label("Replace all downward");
  } else {
    VIM::DoCommand('let g:SEARCH4GVIM_PROMPT=1'); 
    $buttonUp->set_label("Search upward");
    $buttonDown->set_label("Search downward");
  }
}

sub stopf
{
  use vars qw($casecheck $regexpcheck $promptcheck $table $box1 $box2 $buttonAll $buttonReplaceNext);
  VIM::DoCommand('let g:pattern_found=0');
  $buttonUp->set_sensitive (TRUE);
  $buttonDown->set_sensitive (TRUE);
  $box2->set_sensitive (FALSE);
  $table->set_sensitive (TRUE);
  $casecheck->set_sensitive (TRUE);
  $regexpcheck->set_sensitive (TRUE); 
  $promptcheck->set_sensitive (TRUE);
  $buttonAll->set_label("Replace all  "); $buttonReplaceNext->set_label("Replace and go next  ");
}

sub replacealldownup {
  my $dir = $_[0];
  if ($dir ne "up") {$dir="down";}
  use vars qw($search_entry $replace_entry $casecheck $regexpcheck $promptcheck $table $box1 $box2 $direction $buttonAll $buttonReplaceNext);
  msg('');
  my $success; my $expr; my $s; my $r;
  my $search = $search_entry->get_child()->get_text;
  $s = $search; $s =~ s/['"\\\x0]/\\$&/g;
  VIM::DoCommand('let g:SEARCH4GVIM_FFIND="'.$s.'"');
  my $replace = $replace_entry->get_child()->get_text;
  $r = $replace; $r =~ s/['"\\\x0]/\\$&/g;
  VIM::DoCommand('let g:SEARCH4GVIM_RREPL="'.$r.'"');
  ($success,$expr) = VIM::Eval('histget("search",-1)');
  if ($expr ne $search) { VIM::DoCommand('call histadd("search","'.$s.'")'); }
  ($success,$expr) = VIM::Eval('HistRepl_get()');
  if ($expr ne $replace) { VIM::DoCommand('call HistRepl_add("'.$r.'")'); }
  fill_search_repl_history();
  ($success,$expr) = VIM::Eval('g:SEARCH4GVIM_PROMPT');
  if ($expr==0) {
    VIM::DoCommand('call AllWithoutPrompt("' . $dir . '")'); 
    my $chgs = VIM::Eval('g:numfound');
    if ($chgs eq "-1") {msg('Errors in the request patterns.'); stopf();}
    else { 
       if ($chgs eq "0") {msg('Not found. No changes done.'); stopf();}
       else { msg( $chgs . ' changes done' ); }
    }
  }
  else {
    if ($dir eq "down") { VIM::DoCommand('call FindDown()'); }
    else { VIM::DoCommand('call FindUp()'); } 
    ($success,$expr) = VIM::Eval('g:pattern_found');
    if ($expr==1) {
       $direction=$dir;
       $box2->set_sensitive (TRUE);
       $buttonUp->set_sensitive (FALSE);
       $buttonDown->set_sensitive (FALSE);
       $table->set_sensitive (FALSE);
       $casecheck->set_sensitive (FALSE);
       $regexpcheck->set_sensitive (FALSE); 
       $promptcheck->set_sensitive (FALSE);
       if ($dir eq "down") { $buttonAll->set_label("Replace all \N{U+2193}"); $buttonReplaceNext->set_label("Replace and go next \N{U+2193}");}
       else { $buttonAll->set_label("Replace all \N{U+2191}"); $buttonReplaceNext->set_label("Replace and go next \N{U+2191}");}
    }
    else {
       msg('Not found');
    }
  }
}

sub allwithoutprompt
{  use vars qw($direction);
   msg('');
   VIM::DoCommand('call AllWithoutPrompt("' . $direction . '")'); 
   my $chgs = VIM::Eval('g:numfound');
   if ($chgs eq "-1") {msg('Errors in the replace pattern.'); }
   else {
      if ($chgs eq "0") { msg( 'No changes done.' ); }
      else { msg( $chgs . ' changes done' ); }
   }
   stopf();
}

sub replacenext
{
   use vars qw($direction);
   my $success; my $expr;
   msg('');
   VIM::DoCommand('call ReplaceSelected("' . $direction . '")'); 
   my $chgs = VIM::Eval('g:numfound');
   if ($chgs eq "-1") {msg('Errors in the replace pattern.'); stopf();}
   else {   
      if ($direction eq "down") { VIM::DoCommand('call FindDown()'); }
      else { if ($direction eq "up") { VIM::DoCommand('call FindUp()'); } }
     ($success,$expr) = VIM::Eval('g:pattern_found');
     if ($expr==0) {
        msg('Not found');
        stopf();
     }
   }
}

sub replacestop
{
   use vars qw($direction);
   msg('');
   VIM::DoCommand('call ReplaceSelected("' . $direction . '")');
   my $chgs = VIM::Eval('g:numfound');
   if ($chgs eq "-1") {msg('Errors in the replace pattern.');}
   stopf(); 
}

sub skipf
{
   use vars qw($direction);
   my $success; my $expr;
   msg('');
   if ($direction eq "down") {
     VIM::DoCommand('call FindDown()');
   } else {
     if ($direction eq "up") {
       VIM::DoCommand('call FindUp()');
     }
   } 
   ($success,$expr) = VIM::Eval('g:pattern_found');
   if ($expr==0) {
      msg('Not found');
      stopf();
   }
}

our $direction;

# Create the window
my $window = new Gtk2::Window ( "toplevel" );
$window->set_title("Search and Replace");
$window->set_border_width (10);
$window->set_position('center');
$window->set_accept_focus(TRUE);
$window->set_destroy_with_parent(TRUE);
$window->set_keep_above(TRUE);

$window->signal_connect(delete_event => \&delete_event);
$window->signal_connect(destroy => sub { VIM::DoCommand('2match');VIM::DoCommand('match');Gtk2->main_quit; });
$window->signal_connect (key_press_event => sub {
    my ($widget, $event) = @_;
    if ($event->keyval == $Gtk2::Gdk::Keysyms{Escape}) {
       $widget->destroy;
    }
    return 0;
});

my $box0 = Gtk2::VBox->new(FALSE, 3);
our $box1 = Gtk2::HBox->new(FALSE, 3);
our $box2 = Gtk2::HBox->new(FALSE, 3);
my $boxopt = Gtk2::HBox->new(FALSE, 3);
my $separator = Gtk2::HSeparator->new;
my $separator0 = Gtk2::HSeparator->new;

our $status = Gtk2::Label->new;
$status->set_justify('left');

$window->add($box0);

my $success; my $expr;

our $models = Gtk2::ListStore->new ('Glib::String');
our $modelr = Gtk2::ListStore->new ('Glib::String');
our $search_entry = Gtk2::ComboBoxEntry->new($models, 0);
our $replace_entry = Gtk2::ComboBoxEntry->new($modelr, 0);

fill_search_repl_history();

VIM::DoCommand('let g:SEARCH4GVIM_FSEL=""');

our $table = Gtk2::Table->new(2, 2, FALSE);

my $labels = Gtk2::Label->new(" Search for  ");
my $labelr = Gtk2::Label->new(" Replace with  ");

$labels->set_justify('left');
$labelr->set_justify('left');

$table->attach($labels, 0, 1, 0, 1,'shrink','shrink',0,0);
$table->attach($labelr, 0, 1, 1, 2,'shrink','shrink',0,0);
$table->attach($search_entry, 1,2, 0, 1,['fill','expand'],'shrink',0,0);
$table->attach($replace_entry, 1,2, 1, 2,['fill','expand'],'shrink',0,0);

our $casecheck = Gtk2::CheckButton->new_with_label("Case sensitive");
our $regexpcheck = Gtk2::CheckButton->new_with_label("Regular expressions");
our $promptcheck = Gtk2::CheckButton->new_with_label("Prompt on replacement");
my $tooltipcase = Gtk2::Tooltips->new;
my $tooltipregexp = Gtk2::Tooltips->new;
my $tooltipprompt = Gtk2::Tooltips->new;
$tooltipcase->set_tip($casecheck, "Case sensitive search");
$tooltipregexp->set_tip($regexpcheck, "Regular expressions in search request");
$tooltipprompt->set_tip($promptcheck, "Ask confirmation for replacement?");

($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FCASE');
if ($success!=1) {
   VIM::DoCommand('let g:SEARCH4GVIM_FCASE=1');
   $expr = 1;}
if ($expr==1) {$casecheck->set_active(TRUE); }
else {$casecheck->set_active(FALSE); }

($success,$expr) = VIM::Eval('g:SEARCH4GVIM_FREGEXP');
if ($success!=1) {
   VIM::DoCommand('let g:SEARCH4GVIM_FREGEXP=1');
   $expr = 1; }
if ($expr==1) {$regexpcheck->set_active(TRUE); }
else {$regexpcheck->set_active(FALSE); }

($success,$expr) = VIM::Eval('g:SEARCH4GVIM_PROMPT');
if ($success!=1) {
   VIM::DoCommand('let g:SEARCH4GVIM_PROMPT=1');
   $expr = 1; }
if ($expr==1) {
   $promptcheck->set_active(TRUE);
  our $buttonUp = Gtk2::Button->new("Search upward");
  our $buttonDown = Gtk2::Button->new("Search downward");
 }
else {
  $promptcheck->set_active(FALSE); 
  our $buttonUp = Gtk2::Button->new("Replace all upward");
  our $buttonDown = Gtk2::Button->new("Replace all downward");
}

$casecheck->signal_connect(toggled => \&casetoggle, $window);
$regexpcheck->signal_connect(toggled => \&regexptoggle, $window);
$promptcheck->signal_connect(toggled => \&prompttoggle, $window);

my $buttonCancel = Gtk2::Button->new("Cancel");

$buttonUp->signal_connect(clicked => sub { replacealldownup("up"); }, $window);
$buttonDown->signal_connect(clicked => sub { replacealldownup("down"); }, $window);
$buttonCancel->signal_connect(clicked => sub { VIM::DoCommand('2match');VIM::DoCommand('match');$window->destroy; });

$box1->pack_start($buttonDown, TRUE, TRUE, 0);
$box1->pack_start($buttonUp, TRUE, TRUE, 0);
$box1->pack_start($buttonCancel, TRUE, TRUE, 0);

our $buttonReplaceNext = Gtk2::Button->new("Replace and go next  ");
our $buttonSkip = Gtk2::Button->new(" Skip ");
our $buttonReplaceStop = Gtk2::Button->new("Replace and stop");
our $buttonStop = Gtk2::Button->new(" Stop ");
our $buttonAll = Gtk2::Button->new("Replace all  ");

$box2->pack_start($buttonReplaceNext, TRUE, TRUE, 0);
$box2->pack_start($buttonSkip, TRUE, TRUE, 0);
$box2->pack_start($buttonReplaceStop, TRUE, TRUE, 0);
$box2->pack_start($buttonStop, TRUE, TRUE, 0);
$box2->pack_start($buttonAll, TRUE, TRUE, 0);

$buttonReplaceNext->signal_connect(clicked => \&replacenext, $window);
$buttonSkip->signal_connect(clicked => \&skipf, $window);
$buttonReplaceStop->signal_connect(clicked => \&replacestop, $window);
$buttonStop->signal_connect(clicked => \&stopf, $window);
$buttonAll->signal_connect(clicked => \&allwithoutprompt, $window);

$box0->pack_start($table, FALSE, FALSE, 0);
$box0->pack_start($separator0, FALSE, FALSE, 3);
$boxopt->pack_start($casecheck, FALSE, FALSE, 0);
$boxopt->pack_end($regexpcheck, FALSE, FALSE, 0);
$box0->pack_start($boxopt, FALSE, FALSE, 0);
$box0->pack_start($promptcheck, FALSE, FALSE, 0);
$box0->pack_start($separator, FALSE, FALSE, 3);
$box0->pack_start($box1, FALSE, FALSE, 2);
$box0->pack_start($box2, FALSE, FALSE, 2);
$box0->pack_start($status, FALSE, FALSE, 0);

$window->show_all;

$box2->set_sensitive (FALSE);

Gtk2->main;

0;

EOF

return ""

endfunc
endif

