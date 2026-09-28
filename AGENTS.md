# AGENTS.md

This repository is Chorus, a fork of CL-Cuda. The ASDF systems are `chorus`, `chorus-test`, `chorus-examples`, `chorus-misc`, `chorus-interop`, `chorus-interop-test`, and `chorus-interop-examples`. The git remote is chorus.

## Copyright and license

The license is MIT. Leave the permission text in `LICENSE` as it is written.

`LICENSE` and the Copyright section of `README.markdown` name the project: `Copyright (c) 2012-2021 Masayuki Takagi`. That span is his first non-merge commit, in 2012, through his last, in 2021. His non-merge commits fall in 2012, 2013, 2014, 2015, 2016, 2017, 2019, and 2021. The 2020 commit is a merge.

On a source file, Takagi's year is the first and last year of his non-merge commits that touch that file. Use one year when they are the same. Take the years from `git log --follow --no-merges --author=kamonama@gmail.com`. The line includes `(kamonama@gmail.com)`. When you change a file, set his year from that log.

Christopher Mark Gore's notice is `Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)`. Use the year of the edit. When that line is already present and the edit falls in a later year, make the year a range from the first year on the line through the year of the edit.

When you change a file that already carries Takagi's notice, add Gore's line under it. Leave the header of a file you do not change as it is. A new file gets Gore's notice only. When the new file contains code copied from an existing file, keep that file's notice as well.

Use this header, with `<years>` taken from the log above:

```
#|
  This file is a part of the Chorus project.
  Copyright (c) <years> Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#
```

Keep the sentence `This file is a part of the Chorus project.` The system name is chorus.

`LICENSE` lists both copyright lines, then the MIT permission text. `misc/drvapi_error_string.h` is Copyright 1993-2010 NVIDIA Corporation and stays under the terms stated in that file. Leave that file's notice as NVIDIA wrote it.

Other contributors stay in the git history. `LICENSE` and the file headers name Takagi and Gore.

Every system sets `:author` to `"Masayuki Takagi, Christopher Mark Gore"` and `:license` to `"MIT"`. A new system uses the same two values.

The Author and Copyright sections of `README.markdown` list the same people, in the same order.
