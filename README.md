# Public Bug Bounty Search
This is a search engine for content shared publicly via cloud storage services,
built using [Google's Cloud Search Engine (CSE)](https://cse.google.com/cse/).
The tools allows searching across all URLs are are included as part of
bug bounty programs by various platforms.

# Purpose
The purpose of this tool is to aid security researchers and bug bounty hunters.

# Disclaimer
The information that this tool reveals is being indexed by Google and not
being collected by this tool. If you want something to be removed,
please contact Google directly.

**This tool is not affiliated with or endorsed by Google, all trademarks
remain property of their owners. Please use responsibly in accordance with
the applicable laws. We take no responsibility for your use of this tool.**

# How it works
This tool uses Google's CSE to restrict searches against content being
served by the URLs considered in scope by public bug bounty programs.
It is essentially a search engine that is limited to a subset of sites. It is
build via a set of match patterns which are then imported into the CSE console
to build a working search engine. There are also some labels that allow users
to search against specific bug bounty platforms. For more information, see [the official
CSE documentation](https://developers.google.com/custom-search/docs/overview).
While this tool is build using CSE, it can theoretically be rebuild any other
search engine tool that supports similar functionality.

The patterns that this tool uses come from the [bounty-targets-data](https://github.com/arkadiyt/bounty-targets-data) repository by Arkadiy Tetelman ([@arkadiyt](https://github.com/arkadiyt)) which is included as a git submodule, with some code
adapted from his [bounty-targets](https://github.com/arkadiyt/bounty-targets)
repository.

A demo version of the search engine is available [here](https://cse.google.com/cse?cx=001888752746524345906:pccy6kike-k) but it is not guaranteed to be updated
on a regular basis.

# Instructions
1. Make sure you have the latest version of Ruby installed.
2. Clone this repository via Git.
3. Run "git submodule update --init --recursive" to update the data.
4. Login to CSE console and create a new search engine.
5. Switch to "Search Features", "Refinements" section of the CSE console and add
the refinements listed below. Make sure you select "Search only the sites with this label":
   * BugCrowd
   * Federacy
   * HackerOne
6. Switch to "Setup", "Advanced" section and get the search engine tag. It will look like something like this: "__cse_xxxxxxx" where xxxxxx is the tag.
7. Run the included script with the "-t xxxxxx" option. This will generate several
TSV files in the "cse-data" directory.
8. You can upload these files in the CSE console to enable the search, then
visit the search engine link.
9. (OPTIONAL) You can use the "user_content.tsv" file to exclude sites with a lot
of user content that may pollute your search results.

# Limits
As per [CSE documentation](https://developers.google.com/custom-search/docs/annotations#annotations-limits), there is a limit of 2,000 entries per file
and 5,000 entries per search engine.

# Feedback
Please use Github issues and pull requests to provide suggestions and feedback.
For email contact, you can reach out to research@nightwatchcybersecurity.com.
