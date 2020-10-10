IRIDIA BibTeX Repository
========================

[![Build Status](https://travis-ci.com/iridia-ulb/references.svg?branch=master)](https://travis-ci.com/iridia-ulb/references)

PDF file of all references:
[testbib.pdf](https://github.com/iridia-ulb/references/raw/master/test/testbib.pdf) 
[testshortbib.pdf](https://github.com/iridia-ulb/references/raw/master/test/testshortbib.pdf)


[IRIDIA BibTeX Repository Webpage](https://iridia-ulb.github.io/references/)

Before modifying any file, please read and follow the instructions at
the top of each file.



<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**
- [Rationale](#rationale)
- [Format of keys](#format-of-keys)
- [Using the IRIDIA BibTeX Repository](#using-the-iridia-bibtex-repository)
- [Updating your working copy](#updating-your-working-copy)
- [Contributing to the IRIDIA BibTeX Repository](#contributing-to-the-iridia-bibtex-repository)
- [Before submitting a paper](#before-submitting-a-paper)
- [List of most often used git commands](#list-of-most-often-used-git-commands)
- [BibTeX Advice](#bibtex-advice)
- [Frequently Asked Questions](#frequently-asked-questions)
    - [Q: Why are there so many rules?](#q-why-are-there-so-many-rules)
    - [Q: Why not take the entries directly from Google Scholar, DBLP, Elsevier,...?](#q-why-not-take-the-entries-directly-from-google-scholar-dblp-elsevier)
    - [Q: Some entries don't have DOI. This is inconsistent. Or I don't like the DOIs in the references list](#q-some-entries-dont-have-doi-this-is-inconsistent-or-i-dont-like-the-dois-in-the-references-list)
    - [Q: Some entries are Proceedings published by LNCS but the entry does not mention the word "Proceedings" or "Conference"](#q-some-entries-are-proceedings-published-by-lncs-but-the-entry-does-not-mention-the-word-proceedings-or-conference)
    - [Q: Do we need to mention that the Proceedings are published by LNCS? Why not use `@Proceedings` for those?](#q-do-we-need-to-mention-that-the-proceedings-are-published-by-lncs-why-not-use-proceedings-for-those)
    - [Q: A journal insists on using "Springer-Verlag" instead of "Springer", how to change everything?](#q-a-journal-insists-on-using-springer-verlag-instead-of-springer-how-to-change-everything)
    - [Q: I want to save space and abbreviate journal names and titles of books. Should I just edit the journal.bib and abbrev.bib files?](#q-i-want-to-save-space-and-abbreviate-journal-names-and-titles-of-books-should-i-just-edit-the-journalbib-and-abbrevbib-files)
    - [Q: I want to save space and reduce the number of editors (say et   al. for any editor after the first one), or remove all DOIs, URLs,   publisher address or other such fields. Can I edit the .bib files?](#q-i-want-to-save-space-and-reduce-the-number-of-editors-say-et---al-for-any-editor-after-the-first-one-or-remove-all-dois-urls---publisher-address-or-other-such-fields-can-i-edit-the-bib-files)
    - [Q: I made a mistake in the commit message. Can this be fixed?](#q-i-made-a-mistake-in-the-commit-message-can-this-be-fixed)
    - [Q: There is a separate entry for each cross-reference, and individual references cite it. I think it is ugly, how to prevent this?](#q-there-is-a-separate-entry-for-each-cross-reference-and-individual-references-cite-it-i-think-it-is-ugly-how-to-prevent-this)
    - [Q: Why I should not use `{{Title}}` in title? If not, should I use  title case or sentence case?](#q-why-i-should-not-use-title-in-title-if-not-should-i-use--title-case-or-sentence-case)
    - [Q: I want to keep an eye on someone else altering my references by mistake.](#q-i-want-to-keep-an-eye-on-someone-else-altering-my-references-by-mistake)
- [Copyright](#copyright)

<!-- markdown-toc end -->

Rationale
---------

The main motivation for having a single repository is to incrementally
fine-tune and perfect the references by sharing bibtex entries that have been
curated over time by as many people as possible and that are used directly
as-is, that is, without further alteration. Significantly, while errors tend to
persist if they were present when the entry was added, they are almost never
introduced at a later phase since entries are almost never adjusted and any
customization happens via overriding `@String` definitions. Thus, the quality of
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
current system, there is a single definition of an author's name in `authors.bib`
and any mistake will result in a warning for an undefined string when compiling
with bibtex. Moreover, the `@Strings` labels tend to be shorter than what they
expand to and they make searching / grepping much easier. In addition, the use
of `crossref.bib` makes easier to keep consistency in the data for related
publications (conference proceedings, book series, different editions).

Finally, the separation makes trivial to apply various "tricks", such as
switching to a much abbreviated format for conference and journal names. The
idea is to override the desired `@String` definitions rather than editing the
`.bib` files.

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

1. Only use alphanumeric characters plus `:`, `-`. Never use accents
   or non-ASCII characters.

2. Use the first three letters of the first surname of each author (up
   to four authors, first letter capitalized), the full year of
   publication (if this is not known, make a good guess because this
   should not be changed afterwards and it is confusing that the year
   in the key does not matches the year of publication),
   and the acronym of the conference, journal, or publisher. Examples:
```bibtex
      @Article{NouGhiBirDor2005ki,
         author = 	 {S. Nouyan and R. Ghizzioli and
                         M. Birattari and M.  Dorigo},
         journal = 	 KI,
         year = 	 2005,
```
3. If there is a conflict, use another distinct single word, either
   from the title of the paper, or the title of the proceedings. Exceptions are:

   * Proceedings: keys should be the acronym of the proceedings
     followed by the year. Examples: ANTS2008, GECCO2010, etc.

   * Technical Reports: use the identificative key that technical
     reports often have, for example, IRIDIA-2009-015. Be careful to
     not use "`/`", "`\`" or "`,`" in keys.

   * Theses (PhD, etc): after the year, add the type of thesis.
     Example: Birattari2004PhD.


Using the IRIDIA BibTeX Repository
----------------------------------

The IRIDIA BibTex repository is essentially a collection of `bib` files,
so all you need to do is to include these files in your paper.

The `bib` files define some commands, for example `\MaxMinAntSystem`. You
can override any command by just defining it with `\newcommand` or
`\providecommand` before the bibliography line. This trick also works for other
commands defined by BibTeX styles (`.bst`). For example, disabling doi
information can be normally achieved with `\providecommand{\doi}[1]{}`.

However, one of the purposes of this repository is to keep the list of
references as independent as possible from the working paper(s),
whenever possible. Hence, we suggest two main ways of setting up your
local copy of the IRIDIA BibTex repository.
The instructions below work for Linux/Mac, but can of course be adapted
for Windows too.

* **Method A: Symbolic links**

This method is suggested especially when working on your paper offline,
whether you are using a versioning system for your paper or not. In case
you use a versioning system to work on your paper with other collaborators,
make sure everyone in the team uses the IRIDIA BibTex repository and
follows the same instructions.

1. Clone the repository
   ```
   cd /path/to/work/
   git clone https://github.com/iridia-ulb/references.git
   ```

2. In the folder of the working paper, create a link to the local copy
   of the repository.
   ```
   cd /path/to/paper/
   ln -s /path/to/work/references references
   ```
   If you use a versioning system to work on the paper with other coauthors,
   do not add the link to the paper repository; instead, ask your
   collaborators to do the same in their working copy.

3. In the main `tex` file of your paper, include the BibTex files with
   ```latex
    \bibliography{references/abbrev,references/journals,references/authors,references/biblio,references/crossref}
   ```   

4. See the sections ["Updating"](#updating-your-working-copy),
   ["Contributing"](#contributing-to-the-iridia-bibtex-repository), and
   ["Before Submitting a paper"](#before-submitting-a-paper).


* **Method B: fake submodule**

This method is suggested in case you work on your paper (alone or with your
collaborators) on web-based systems such as Overleaf.

1. Within your existing local repository, create a *fake submodule*. The trailing "slash (`/`) is important!

```
    git clone https://github.com/iridia-ulb/references.git references
    git add references/
```

2. Now `git` commands at the top directory operate in your own git
   repository, but `git` commands within the directory `references` operate in
   the `iridia-ulb` repository. The `references` directory will be available to
   all users of the repository, however, only the users who perform the above
   command can perform operations in the `iridia-ulb` repository.

3. In the main `tex` file of your paper, include the BibTex files with
   ```latex
    \bibliography{references/abbrev,references/journals,references/authors,references/biblio,references/crossref}
   ```

4. See the sections ["Updating"](#updating-your-working-copy),
   ["Contributing"](#contributing-to-the-iridia-bibtex-repository), and
   ["Before Submitting a paper"](#before-submitting-a-paper).   


* **Method C: worktrees**

This method is suggested if you have write access to the iridia-ulb
repository and you want to update the master repository frequently.

1. Get a copy of the master repository in some folder, e.g., `/path/to/references-master`:

```
    git clone https://github.com/iridia-ulb/references.git /path/to/references-master
```

2. Now, assuming that your paper resides in `/path/to/mypaper`, create a branch
   and a worktree for your paper:
   
```
    cd /path/to/references-master
    git worktree add -b mypaper /path/to/mypaper/references
```
   
3. If you wish to import changes from the master branch, you do:
```
    cd /path/to/mypaper/references
    git rebase -i master
```

4. If you wish to push changes to iridia-ulb master, you do:
```
    cd /path/to/references-master
    git merge --ff-only mypaper
    git push
```
5. You can also easily find out which worktrees need to be merged into master:
```
    git branch --no-merged master
```

* **Other methods**

  You might prefer alternative ways of setting up the local copy of this
  repository. However, be aware that this might come with additional burden
  (for you) of managing the consistency and compatibility with the main central
  repository.  We especially discourage methods that "break" the tracking of
  the changes, such as copying or linking single files.

  Should you go this way (e.g. because you or your collaborators are already
  used to a certain workflow) please be aware that it will be your
  responsibility to keep your local copy updated, in particular when you
  submit your changes (see Section ["Contributing"](#contributing-to-the-iridia-bibtex-repository)).


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

Remove the incorrect text and the markers, save, commit and push the changes
```bash
    git add FILE
    git commit -m "FILE: conflict resolved"
    git push
```

Git may create a merge commit when you pull/push if you have local commits. It is better to configure git to *replay* your commits on
top of the changes in the server:

    git config branch.master.rebase true

If you are making many *dirty* commits locally before syncing with the server,
it is better to create a branch/fork and merge it with `master` once you are
ready.


Contributing to the IRIDIA BibTeX Repository
--------------------------------------------

If you are a member of the [iridia-ulb GitHub organization](https://github.com/iridia-ulb),
or if you have been given access to the
[references repository](https://github.com/iridia-ulb/references),
you can push your commits directly to the repository.
Otherwise, you can submit your [contribution with a pull request](https://help.github.com/en/articles/about-pull-requests).

Before committing any change, follow first ["Updating your working
copy"](#updating-your-working-copy), then use

    git diff
and

    git status

to check that your local changes are really what you want to
commit. Please do not commit changes that do not follow the rules
described above and within each bib file. Changes that are not
incremental to the latest online version will be rejected.

Add the files with the changes you want to submit to the
repository using

    git add LIST OF FILES

and commit the changes with any of the following commands:

    git commit -m "log_message"
    git commit -F LOG_MESSAGE_FILE
    git commit

(see `git help commit` for more ways to specify the log message).

The third method will open an editor (set the environment variable `$EDITOR` to
customize it) where you can write your commit message. The first line of the
commit is equivalent to the `"log_message"` specified using the `-m` option,
and it is essentially a title.

In case of a commit with many edits, it is recommended to use
either the `-F` or the editor option, with the possibility of
having a longer and more clear message body.

The commit message (log message) should be of the following form:

    * file (entry): What changed.

Example:
```
    * biblio.bib (AngWoo2009:ejor): New entry.
    (Asc2001t:cor): Update year.
    * crossref.bib (GECCO2000): Fix editor names.
```
Finally, push the commits to the repository with

    git push

***IMPORTANT:*** If you use non-ASCII characters BE SURE that your editor
uses UTF8 encoding. Otherwise, ***DO NOT USE*** non-ASCII characters.

***IMPORTANT:*** If you have modified a `tex` or `bib` file (as it is often the
case), the push will trigger a compilation using the Travis continuous
integration system (which should take at most a couple of minutes).  If the
compilation fails, you will receive an email; in this case, fix the error and
retry.  If the build is successful, the resulting file `test/testbib.pdf` will
be automatically pushed to the repository.  This automatic step is effectively
a new commit, so make sure you do another

    git pull

to sync your local repo before modifying again the files.


Before submitting a paper
-------------------------

If you prefer to not submit several `*.bib` files, just use the program
[`aux2bib`](https://ctan.org/pkg/bibtools?lang=en) to generate a BibTeX file
with only the entries that you are using.

If you find a mistake on the generated file or want to add new
entries, you should modify your working copy, and then run `aux2bib`
again to regenerate the file.

Some bibtex styles generate separated entries for cross references. See the
[corresponding answer in the FAQ below](#q-there-is-a-separate-entry-for-each-cross-reference-and-individual-references-cite-it-i-think-it-is-ugly-how-to-prevent-this).


If you want to modify a bibtex style to use short names (only the
initial for the name), edit the `*.bst` file, search for something such
as:

        {ff~}{vv~}{ll}{, jj}" format.name$

and replace it with:

        {f.~}{vv~}{ll}{, jj}" format.name$



List of most often used git commands
------------------------------------

This is a very basic list of the most useful commands, to get the most
out of Git, please read the book: https://git-scm.com/book/en/

An explanation of the commands can also be found with

        git help

in general, or

        git help COMMAND

to get the various option of the specific command COMMAND.

* Checkout a copy of the files to some directory:

        git clone https://github.com/iridia-ulb/references references

* Update your local copy with the changes in the repository

        git pull

  (avoid empty merge commits with `git config  branch.master.rebase true` or
  `git pull --rebase`)
  
* See your local changes (both staged and not staged yet)

        git diff HEAD

* See the current status of your local copy, such as which files have
  been modified since the last commit, or which files are untracked

        git status

* Select the files that you want to include (stage) in the commit. There might
  be files with changes not yet ready for commit, so include only what you
  consider to be in a consistent state

        git add LIST OF FILES

* Commit changes to your local repository:

        git commit -m "log_message"
        git commit -F COMMIT_FILE
        git commit

   (see `git help commit` for more ways to specify the log message). The third
   method will open an editor (set the environment variable `$EDITOR` to
   customize it) where you can write your commit message. The first line of the
   commit is equivalent to the `"log_message"` specified using the `-m` option,
   and it is essentially a title.

* Send changes to the github repository:

        git push



BibTeX Advice
-------------

There is advice at the top of each .bib file about the contents within that
file. The following is general advice on how to format bib entries.

 * Do not use non-ASCII characters unless you use UTF-8. It may be better to
   just use LaTeX instead, that is, instead of "í" use `{\'\i}`.  In
   [Emacs](https://www.gnu.org/software/emacs/), one can use `'(occur
   "[^[:ascii:]]"))'` to find all non-ASCII characters.

 * `'doi'` field is just the DOI, without the http://dx.doi.org/


Frequently Asked Questions
--------------------------

#### Q: Why are there so many rules? ####

A: An incomplete list of reasons:

 * Rules are there to prevent mistakes that may not be obvious in your document
   but that will be when using a different citation style (author-year,
   numerical, alphanumerical, ...)  and/or bibliography style.

 * We owe to authors whom we cite that we reference their work as faithfully as
   possible. Rules are there to ensure consistency and correctness.
   
 * References in published work are often parsed by machines to determine
   citation counts. If the reference is incorrect or not detailed enough, the
   citation may not be counted correctly by such systems.
 
 * Experience has shown that there are some common tricks and tips that are
   rather obscure but prevent certain errors. Many of the rules are inspired by
   the document: [BibTeX Tips and FAQ](http://mirrors.ctan.org/biblio/bibtex/contrib/doc/btxFAQ.pdf).


#### Q: Why not take the entries directly from Google Scholar, DBLP, Elsevier,...? ####

A: BibTeX entries generated by Google Scholar and Citeseer are of extremely
poor quality and should NEVER be trusted. Entries generated by
[DBLP](https://dblp.org/) are much better but they often use the full title of
proceedings, which includes the date and location of the conference in the
title, as the `@booktitle`, which is impractical.  Also, fields that only
matter to DBLP, such as `@bibsource`, are useless and should be removed.
BibTeX entries provided by publishers such as ACM, Elsevier or Springer are
often wrong and contradict their own suggested way of citing a work. It is
often better to look at how they suggest to cite it and write a BibTeX entry
that recreates it.

#### Q: Some entries don't have DOI. This is inconsistent. Or I don't like the DOIs in the references list ####

A: Ideally, we would have the DOI of everything, since it helps to find the
actual paper and verify its details. Let the bibtex style control whether
to show it or not. In practice, it is very easy to hide all DOIs, either by
redefining the command that prints the doi or commenting out a few lines in the
bibtex style. Thus, one should ALWAYS add a DOI if possible.

#### Q: Some entries are Proceedings published by LNCS but the entry does not mention the word "Proceedings" or "Conference" ####

A: Those are the official names of the books (except for mistakes that should
   be fixed). This is how Springer recommends to cite them and how DBLP cites
   them. There is no reason to call the book by a different title from its
   actual title.
    
#### Q: Do we need to mention that the Proceedings are published by LNCS? Why not use `@Proceedings` for those? ####
   
A: There is an important difference in terms of publication importance. LNCS
are books (`@Book`) published by Springer and they contain peer-reviewed
article-length papers/chapters. That is different from conference proceedings
(`@Proceedings`) published by the conference organisation themselves that may
not be available in book form, may not be peer-reviewed and may contain only
abstracts. Citations from/to LNCS are counted by JCR. For some funding
agencies, LNCS count almost as much as journal publications.

#### Q: A journal insists on using "Springer-Verlag" instead of "Springer", how to change everything? ####

A: You could generate the `*.bbl` file once and edit it, but if you need
   to recompile the bibliography, you'll have to edit it again.

  A better way is to create a `dummy.bib` file with:
```bibtex
    @string{springer = "Springer-Verlag"}
    @string{springer-lncs = "Springer-Verlag, Heidelberg, Germany"}
```
  ... and so on, and then include it *after* `abbrev.bib`:
```latex
    \bibliography{abbrev,authors,journals,dummy,biblio,crossref}
```

#### Q: I want to save space and abbreviate journal names and titles of books. Should I just edit the journal.bib and abbrev.bib files? ####

A: You could do that, but you cannot commit the changes. So it would
   be cumbersome for you to maintain your own copy.

   You could generate the `*.bbl` file once and edit it, but if you need
   to recompile the bibliography, you'll have to edit it again.

   The best way is to add the shorter variants to `abbrevshort.bib`, and
   then include it *after* both `abbrev.bib` and `journals.bib`:
```latex
    \bibliography{abbrev,authors,journals,abbrevshort,biblio,crossref}
```
   Moreover, if you want to abbreviate titles of books but not journal
   names, then use:
```latex
    \bibliography{abbrev,authors,abbrevshort,journals,biblio,crossref}
```

#### Q: I want to save space and reduce the number of editors (say et   al. for any editor after the first one), or remove all DOIs, URLs,   publisher address or other such fields. Can I edit the .bib files? ####

A: You could do that, but you cannot commit the changes since the
   additional information could be useful for others.  It would be
   cumbersome for you to maintain your own copy, so an automatic way
   to make these changes would be better.

   The best way is to edit the BibTeX style file (`.bst`) to not emit these
   fields. Unfortunately, editing `.bst` files is sometimes not trivial,
   but often one can find examples in Internet. If you edit a popular
   bst file to make it shorter, commit the new version to optbib so
   others can use it. Currently, there is an abbreviated version of
   Springer's LNCS bst file.


#### Q: I made a mistake in the commit message. Can this be fixed? ####

A: Yes, using: `git commit --amend`. More information
   [here](https://help.github.com/en/articles/changing-a-commit-message).


#### Q: There is a separate entry for each cross-reference, and individual references cite it. I think it is ugly, how to prevent this? ####

A: Unhelpfully, bibtex generates by default separated entries for
   cross references. To avoid this, use `bibtex -min-crossrefs=9000`.
   Or use the bibtex wrapper included in the repository.
   If you use Overleaf, you can add a file `.latexmkrc` with the following
   line:

    $bibtex = "bibtex -min-crossrefs=999 %O %S";


#### Q: Why I should not use `{{Title}}` in title? If not, should I use  title case or sentence case? ####

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


#### Q: I want to keep an eye on someone else altering my references by mistake. ####

A: You can click on the "Watch" and "Star" buttons on top of the [GitHub
   page](https://github.com/iridia-ulb/references). You can also fork the
   repository and only merge changes into your fork that you have reviewed.


Copyright
---------

To the extent that the contents of bib files may be subject to
copyright, the contents of the IRIDIA BibTeX Repository are placed
under the public domain by associating it to the Creative Commons CC0
1.0 Universal license (http://creativecommons.org/publicdomain/zero/1.0/).

As a personal note, we will appreciate if modifications are submitted back to
us for consideration.
