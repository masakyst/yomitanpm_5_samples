package Flaskr::View::MicroTemplate::DataSection {
    use Moose; extends 'Catalyst::View::MicroTemplate::DataSection';
    sub _build_section { 'main' }
};

package Flaskr::Controller::Root {
    use Moose; BEGIN { extends 'Catalyst::Controller' }
    use Teng::Schema::Loader;

    __PACKAGE__->config(namespace => '');

    sub index :Path :Args(0) {
        my ($self, $c) = @_;
        if ($c->session->{username}) {
            $c->stash->{username} = $c->session->{username};
        }
        $c->stash->{loggedin} = $c->session->{loggedin};
        my @entries = $c->teng->search(entries => {}, {order_by => 'id DESC'});
        $c->stash->{entries} = \@entries;
    }

    sub add :Local {
        my ($self, $c) = @_;
        my $params = $c->req->body_params;
        $c->teng->insert(entries => {title => $params->{title}, 'text' => $params->{text}});
        $c->res->redirect('/');
    }

    sub login :Local {
        my ($self, $c) = @_;
        $c->stash->{error} = '';
        if ($c->req->method eq 'POST') {
             if ($c->req->body_params->{username} ne 'yomitan') {
                $c->stash->{error} = 'username is Invalid'; 
             }
             elsif ($c->req->body_params->{password} ne '#5') {
                $c->stash->{error} = 'password is Invalid'; 
             }
             unless ($c->stash->{error}) {
                 $c->stash->{username} = 'yomitan.pm';
                 $c->session->{username} = $c->stash->{username};
                 $c->session->{loggedin} = 1;
                 $c->res->redirect('/');
             }
        }
    }

    sub logout :Local {
        my ($self, $c) = @_;
        $c->session->{username} = undef;
        $c->session->{loggedin} = undef;
        $c->res->redirect('/');
    }

    sub end : ActionClass('RenderView') {}
};

package Flaskr 0.01 {
    use Moose;
    use Catalyst::Runtime 5.80;
    use Catalyst qw/
        Static::Simple
        Session
        Session::Store::FastMmap
        Session::State::Cookie
    /;
    extends 'Catalyst';
    use DBI;
    sub teng {
        my $teng = Teng::Schema::Loader->load(
            dbh => DBI->connect('dbi:SQLite:flaskr.db', '', '', {RaiseError => 1, AutoCommit => 1, sqlite_unicode => 1}),
            namespace => 'Flaskr::DB',
        );
        if (-s 'flaskr.db' == 0) {
            $teng->do('create table entries (
                id integer primary key autoincrement, title string not null, text string not null);');
        }
        return $teng; 
    }
    __PACKAGE__->config(encoding => 'utf8', root => './root',);  
    __PACKAGE__->setup();
};

package main;
Flaskr->psgi_app;

__DATA__

@@ index.mt
? my $stash = shift;
<!doctype html>
<title>Flaskr</title>
<link rel=stylesheet type=text/css href="static/style.css">
<div class=page>
  <h1>Flaskr</h1>
  <div class=metanav>
? if ($stash->{username}) {
  <?= $stash->{username} ?>
? }
? if ($stash->{loggedin}) {
    <a href="/logout">log out</a>
? } else {
    <a href="/login">log in</a>
? }
  </div>
? if ($stash->{loggedin}) {
  <form action="/add" method=post class=add-entry>
  <dl>
  <dt>Title:
  <dd><input type=text size=30 name=title>
  <dt>Text:
  <dd><textarea name=text rows=5 cols=40></textarea>
  <dd><input type=submit value=Share>
  </dl>
  </form>
? }
  <ul class=entries>
? for my $entry (@{ $stash->{entries} }) {
  <li><h2><?= $entry->title ?></h2><?= $entry->text ?></li>
? }
  </ul>
</div>

@@ login.mt
? my $stash = shift;
<!doctype html>
<title>Flaskr</title>
<link rel=stylesheet type=text/css href="static/style.css">
<div class=page>
  <h1>Flaskr</h1>
  <div class=metanav>
    <a href="">log in</a>
  </div>
<h2>Login</h2>
? if ($stash->{error}) {
<p class=error><strong>Error:</strong> <?= $stash->{error} ?>
? }
<form action="/login" method="POST">
<dl>
<dt>Username: 
<dd><input type="text" name="username">
<dt>Password:
<dd><input type="password" name="password">
<dd><input type=submit value=Login>
</dl>
</form>
</div>
