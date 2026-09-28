# AGENTS.md

This repository is the cl-cuda library. The ASDF systems are named cl-cuda. The git remote is chorus.

## Copyright and license

The license is MIT. Leave the permission text in `LICENSE` as it is written.

`LICENSE` and the Copyright section of `README.markdown` name the project: `Copyright (c) 2012-2021 Masayuki Takagi`. That span is his first non-merge commit, in 2012, through his last, in 2021. His non-merge commits fall in 2012, 2013, 2014, 2015, 2016, 2017, 2019, and 2021. The 2020 commit is a merge.

On a source file, Takagi's year is the first and last year of his non-merge commits that touch that file. Use one year when they are the same. Take the years from `git log --follow --no-merges --author=kamonama@gmail.com`. The line includes `(kamonama@gmail.com)`. Notices that already said 2013 or 2014 were left as written. When you change one of those files, set his year from that same log.

Christopher Mark Gore's notice is `Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)`. Use the year of the edit. When that line is already present and the edit falls in a later year, make the year a range from the first year on the line through the year of the edit.

When you change a file that already carries Takagi's notice, add Gore's line under it. Leave the header of a file you do not change as it is. A new file gets Gore's notice only. When the new file contains code copied from an existing file, keep that file's notice as well.

Use this header, with `<years>` taken from the log above:

```
#|
  This file is a part of cl-cuda project.
  Copyright (c) <years> Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#
```

Keep the sentence `This file is a part of cl-cuda project.` The system name is cl-cuda.

`LICENSE` lists both copyright lines, then the MIT permission text. `misc/drvapi_error_string.h` is Copyright 1993-2010 NVIDIA Corporation and stays under the terms stated in that file. Leave that file's notice as NVIDIA wrote it.

Other contributors stay in the git history. `LICENSE` and the file headers name Takagi and Gore.

In `cl-cuda.asd` and `cl-cuda-test.asd`, `:author` is `"Masayuki Takagi, Christopher Mark Gore"` and `:license` is `"MIT"`. The other systems keep `:author "Masayuki Takagi"` until you change them. When you change another system, add Gore's name to `:author` and leave `:license` as `"MIT"`.

The Author and Copyright sections of `README.markdown` list the same people, in the same order.
