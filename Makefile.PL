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
    PREREQ_PM       => {
        'Mojo::Base'                    => 0,
        'DateTime'                      => 0,
        'DateTime::Format::DateParse'   => 0,
        'Mail::RFC822::Address'         => 0,
        'List::MoreUtils'               => 0,
    }
);
