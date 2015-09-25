package Hello::Controller::Root {
    use Moose; BEGIN { extends 'Catalyst::Controller' }
    __PACKAGE__->config(namespace => '');

    sub index :Path :Args(0) {
        my ($self, $c) = @_;
        $c->response->body("hello Yomitan.pm");
    }

    sub end : ActionClass('RenderView') {}
};

package Hello 0.01 {
    use Moose;
    use Catalyst::Runtime 5.80;
    extends 'Catalyst';
    __PACKAGE__->setup();
};

Hello->psgi_app;
