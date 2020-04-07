% for version in data["versions"]:
<%
title = "%s (%s)" % (version["tag"], version["date"]) if version["tag"] else opts["unreleased_version_label"]
nb_sections = len(version["sections"])
%>${"# " + title}
% for section in version["sections"]:
% if not (section["label"] == "Other" and nb_sections == 1):

${"## " + section["label"] + "\n"}
% endif
% for commit in section["commits"]:
<%
if commit["body"]:
    subject = "%s [%s]" % (commit["subject"], commit["body"])
else:
    subject = "%s" % commit["subject"]
entry = indent(subject, first="- ").strip("\n ")
%>${entry}
% endfor
% endfor

% endfor

