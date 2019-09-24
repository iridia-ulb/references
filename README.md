IRIDIA BibTeX Repository
========================

[![Build Status](https://travis-ci.com/iridia-ulb/references.svg?branch=master)](https://travis-ci.com/iridia-ulb/references) 

Before modifying any file, please read and follow the instructions at
the top of each file.

PDF file of all references: [testbib.pdf](https://github.com/iridia-ulb/references/raw/master/test/testbib.pdf)


Contents
--------

 * [Rationale](#rationale)
 * Format of keys.
 * [Contributing to the IRIDIA BibTeX Repository](#contributing-to-the-iridia-bibtex-repository)
 * Using the IRIDIA BibTeX Repository
 * Updating your working copy
 * Before submitting a paper
 * List of most often used Subversion commands
 * Copyright
 * BibTeX Advice
 * [Howto: Advanced usage](#howto-advanced-usage)
 * [TODO](#todo)


Rationale
---------

The main motivation for having a single repository is to incrementally
fine-tune and perfect the references by sharing bibtex entries that have been
curated over time by as many people as possible and that are used directly
as-is, that is, without further alteration. Significantly, while errors tend to
persist if they were present when the entry was added, they are almost never
introduced at a later phase since entries are almost never adjusted and any
customization happens via overriding @String definitions. Thus, the quality of
the references monotonically increases with time.

By contrast, manually copying and customizing a subset of entries often fails
to backport any improvements, tends to introduce errors when entries are
incorrectly modified for the sake of consistency and leads to repeated work and
mistakes.

Since the goal is to share high-quality entries rather than a comprehensive
repository, it is better to not add entries if one is unsure about correctness
and short of time to double-check and fix them. In that case, it is better to
keep those entries in a separate personal bib file until one has time to fix
them.

The motivation for the current separation between authors, journals, abbrev,
biblio and crossref files is to avoid spurious divergences of common strings.
In particular, keeping author names consistent is problematic given non-ascii
characters, the not-so-obvious grouping rules for names with more than two
words and differences between full names and abbreviated names. With the
current system, there is a single definition of an author's name in authors.bib
and any mistake will result in a warning for an undefined string when compiling
with bibtex. Moreover, the @Strings labels tend to be shorter than what they
expand to and they make searching / grepping much easier. In addition, the use
of crossref.bib makes easier to keep consistency in the data for related
publications (conference proceedings, book series, different editions).

Finally, the separation makes trivial to apply various "tricks", such as
switching to a much abbreviated format for conference and journal names. The
idea is to override the desired @String definitions rather than editing the
.bib files.

Although some software tools (Mendeley, Zotero, etc) aim to achieve similar
goals, they tend to introduce spurious fields, many of them fail to achieve
consistency, they do not export correct bibtex entries in corner cases, and not
everyone wishes to use the same software. The current system is software
agnostic and can be used with any editor (although Emacs is certainly
recommended).


Format of keys
--------------

When any bib entry is added, the key should be constructed following
these rules:

1. Only use alphanumeric characters plus ':', '-'. Never use accents
   or non-ASCII characters.

2. Use the first three letters of the first surname of each author (up
   to four authors, first letter capitalized), the full year of
   publication (if this is not known, make a good guess because this
   should not be changed afterwards and it is confusing that the year
   in the key does not matches the year of publication), 
   and the acronym of the conference, journal, or publisher.

   Examples: 

      @Article{NouGhiBirDor2005ki,
         author = 	 {S. Nouyan and R. Ghizzioli and 
                         M. Birattari and M.  Dorigo},
         journal = 	 KI,
         year = 	 2005,

3. If there is a conflict, use another distinct single word, either
   from the title of the paper, or the title of the proceedings.

4. Exceptions are:

   * Proceedings: keys should be the acronym of the proceedings
     followed by the year. Examples: ANTS2008, GECCO2010, etc.


   * Technical Reports: use the identificative key that technical
     reports often have, for example, IRIDIA-2009-015. Be careful to
     not use '/', '\' or ',' in keys.
   
   * Theses (PhD, etc): after the year, add the type of thesis.
     Examples: Birattari2004PhD.


Contributing to the IRIDIA BibTeX Repository
--------------------------------------------

People with a SVN account are able to commit changes. People
subscribed to the optbibsvn@iridia.ulb.ac.be mailing list will be able
to see the commit, review it and ask for modifications.

Before committing any change, follow first "Updating your working
copy", then use

    git diff

and

    git status

to check that your local changes are really what you want to
commit. Please do not commit changes that do not follow the rules
described above and within each bib file.

Add the files with the changes you want to submit to the
repository using

    git add LIST OF FILES

and commit the changes with any of the following commands:

    git commit -m "log_message"
    git commit -F COMMIT_FILE
    git commit

(see `git help commit` for more ways to specify the log message).

The third method will open a vi editor where you can write your
commit message. The first line of the commit is equivalent to
the "log_message" specified using the `-m` option, and it is
essentially a title.

In case of a commit with many edits, it is recommended to use
either the `-F` or the editor option, with the possibility of
having a longer and more clear message body.

The commit message (log message) should be of the following form:

    * file (entry): What changed.

Example:

    * biblio.bib (AngWoo2009:ejor): New entry.
    (Asc2001t:cor): Update year.
    * crossref.bib (GECCO2000): Fix editor names.

IMPORTANT: If you use non-ASCII characters BE SURE that your editor
uses UTF8 encoding. Otherwise, DO NOT USE non-ASCII characters.


Using the IRIDIA BibTeX Repository
----------------------------------

To use the *.bib files, you need to keep a copy (or a symbolic link)
in the directory of your paper and use the following line in your main
.tex file:

    \bibliography{abbrev,journals,authors,biblio,crossref}

You may also checkout (or symbolic link to) a copy of the whole optbib
repository into a directory 'optbib' and use:

    \bibliography{optbib/abbrev,optbib/journals,optbib/authors,optbib/biblio,optbib/crossref}



The bib files define some commands, for example \MaxMinAntSystem. You
can override any command by just defining it with \newcommand or
\providecommand before the bibliography line. This trick also works for other
commands defined by BibTeX styles (.bst). For example, disabling doi
information can be normally achieved with \providecommand{\doi}[1]{}.


There are three methods to keep your copy of the files in sync with
the IRIDIA BibTeX Repository:


 * Method A (if you do not use subversion for your paper)

1. Checkout a copy of the files to the directory of the paper.

   svn co https://iridia-dev.ulb.ac.be/projects/optbib/svn/ .

2. See the sections "Updating", "Contributing", and "Before
   Submitting a paper".


 * Method B (if you do use subversion for your paper)

1. Checkout a copy of the files to some directory. This directory is
   your working copy.

   svn co https://iridia-dev.ulb.ac.be/projects/optbib/svn/ bib

2. Then copy all *.bib files to the directory of your paper. If you
   instead create symbolic links (see ln --help), you do not need to
   copy files back and forth between directories to keep them in sync.

3. If you copy the files, you will have to copy the files again to the
   directory of your paper after "Updating your working copy".

4. Similarly, you will have to copy the files from the directory of
   your paper to your working copy before following the instructions
   described in "Contributing".


 * Method C (svn:external)

Read about svn:external in the Subversion book:

     http://svnbook.red-bean.com/


Updating your working copy
--------------------------

You may update your working copy with the changes in the repository
with the following command:

    git pull

This will change your local files and you may need to resolve
conflicts between your changes and the changes in the repository. To
resolve a conflict, edit the file, look for markers such as:

```
>>>>
my change
---------
the repository change
<<<<<
```

Remove the incorrect text and the markers and run

    svn resolved filename


Before submitting a paper
-------------------------

It is preferable that you do not submit all *.bib files. Use the
program aux2bib to generate a BibTeX file with only the entries that
you are using. 

If you find a mistake on the generated file or want to add new
entries, you should modify your working copy, and then run aux2bib
again to regenerate the file.

Some bibtex styles generate separated entries for cross references. To
avoid this use `bibtex -min-crossrefs=9000'. Or use the bibtex wrapper
included in the repository.

If you want to modify a bibtex style to use short names (only the
initial for the name), edit the *.bst file, search for something such
as:

        {ff~}{vv~}{ll}{, jj}" format.name$

and replace it with:

        {f.~}{vv~}{ll}{, jj}" format.name$



List of most often used Subversion commands
-------------------------------------------

This is a very basic list of the most useful commands, to get the most
out of Subversion, please read the book: http://svnbook.red-bean.com/

* Checkout a copy of the files to some directory:

     svn co https://iridia-dev.ulb.ac.be/projects/optbib/svn/

* See changes in the repository before updating:

     svn diff -rBASE:HEAD https://iridia-dev.ulb.ac.be/projects/optbib/svn/

* Update your local copy with the changes in the repository

     svn up

* See your local changes

     svn diff

* Commit changes:

    svn ci -F log_message_file
  or
    svn ci --editor-cmd EDITOR

  where EDITOR is something like emacs, vi or gedit. You can see
  EDITOR in your .bashrc, and then you don't need to specify it every
  time. For short commit messages, you can use 

    svn ci -m " message "


Copyright
---------

To the extent that the contents of bib files may be subject to
copyright, the contents of the IRIDIA BibTeX Repository are placed
under the public domain by associating it to the Creative Commons CC0
1.0 Universal license (http://creativecommons.org/publicdomain/zero/1.0/).

As a personal note, we will appreciate if modifications are submitted back to
us for consideration.



BibTeX Advice
--------------

There is advice at the top of each .bib file about the contents within that
file. The following is general advice on how to format bib entries.

 * Do not use non-ASCII characters, different editors from different OSs will
   mess them up and not all BibTeX versions support them. Use LaTeX instead. In
   emacs, one can use '(occur "[^[:ascii:]]"))'

 * 'doi' field is just the DOI, without the http://dx.doi.org/

 * Do not use fields: publisher, ISSN in `@article`



Howto: Advanced Usage
---------------------------

Q: A journal insists on using "Springer-Verlag" instead of "Springer",
   how to change everything?

A: You could generate the *.bbl file once and edit it, but if you need
   to recompile the bibliography, you'll have to edit it again.

  A better way is to create a dummy.bib file with:
  
    @string{springer = "Springer-Verlag"}
    @string{springer-lncs = "Springer-Verlag, Heidelberg, Germany"}

  ... and so on, and then include it *after* abbrev.bib:

    \bibliography{abbrev,authors,journals,dummy,biblio,crossref}


Q: I want to save space and abbreviate journal names and titles of
   books. Should I just edit the journal.bib and abbrev.bib files?

A: You could do that, but you cannot commit the changes. So it would
   be cumbersome for you to maintain your own copy.

   You could generate the *.bbl file once and edit it, but if you need
   to recompile the bibliography, you'll have to edit it again.

   The best way is to add the shorter variants to abbrevshort.bib, and
   then include it *after* both abbrev.bib and journals.bib:

    \bibliography{abbrev,authors,journals,abbrevshort,biblio,crossref}

   Moreover, if you want to abbreviate titles of books but not journal
   names, then use:

    \bibliography{abbrev,authors,abbrevshort,journals,biblio,crossref}


Q: I want to save space and reduce the number of editors (say et
   al. for any editor after the first one), or remove all DOIs, URLs,
   publisher address or other such fields. Can I edit the .bib files?

A: You could do that, but you cannot commit the changes since the
   additional information could be useful for others.  It would be
   cumbersome for you to maintain your own copy, so an automatic way
   to make these changes would be better.

   The best way is to edit the BibTeX style file (.bst) to not emit these
   fields. Unfortunately, editing .bst files is sometimes not trivial,
   but often one can find examples in Internet. If you edit a popular
   bst file to make it shorter, commit the new version to optbib so
   others can use it. Currently, there is an abbreviated version of
   Springer's LNCS bst file.


Q: I made a mistake in the commit message. Can this be fixed?

A: Yes: `svn propedit 'svn:log' --revprop -r REVISION`


Q: There is a separate entry for each cross-reference, and individual
   references cite it. I think it is ugly, how to prevent this?

A: Unhelpfully, bibtex generates by default separated entries for
   cross references. To avoid this, use `bibtex -min-crossrefs=9000'.
   Or use the bibtex wrapper included in the repository.


Q: Why I should not use "{{Title}}" in title? If not, should I use
   title case or sentence case?

A: Because it prevents the bibtex style to change the case of the
   title to the style used by the journal, it breaks consistency: Some
   titles will be in a case style different from others. In fact,
   most journals use sentence case for journal papers. Sentence case
   is like "This is a title". However, some journals use title case:
   "This Is a Title". Since a bibtex style can convert from title case
   to sentence case, but not the other way around, it is always better
   to use title case in bib files without adding braces around the
   whole title. That is, instead of:
   
    title = {{This is a title that Manuel likes}}

   use 

    title = "This Is a Title that {M}anuel Likes"

Q: I want to keep an eye on someone else altering my references by
   mistake.

A: Send an email to optbibsvn@iridia.ulb.ac.be asking to subscribe to
   the commit emails.


TODO
----

 * Improve 'mklog' to detect files changed, new entries, deleted entries,
   updates and prefill a commit log template.
   

