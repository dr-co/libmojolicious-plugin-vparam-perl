use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Mojolicious::Plugin::Validator",
    VERSION_FROM    => "lib/Mojolicious/Plugin/Validator.pm",
    ABSTRACT_FROM   => "lib/Mojolicious/Plugin/Validator.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
);
