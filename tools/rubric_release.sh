#!/usr/bin/env bash

echo "NOTE: This is a temporary release process."

# Requires robot to be installed
command -v robot 1> /dev/null 2>&1 || \
  { echo >&2 "robot required but it's not installed.  Aborting."; exit 1; }

# Start by assuming it was the path invoked.
THIS_SCRIPT="$0"

# Handle resolving symlinks to this script.
# Using ls instead of readlink, because bsd and gnu flavors
# have different behavior.
while [ -h "$THIS_SCRIPT" ] ; do
  ls=`ls -ld "$THIS_SCRIPT"`
  # Drop everything prior to ->
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    THIS_SCRIPT="$link"
  else
    THIS_SCRIPT=`dirname "$THIS_SCRIPT"`/"$link"
  fi
done

# Get path, set variables
SCRIPT_DIR=$(dirname "${THIS_SCRIPT}")
RUBRIC="${SCRIPT_DIR}/../src/ontology/rubric-edit.owl"
LOG="${SCRIPT_DIR}/rubric-update-log-`date '+%Y-%m-%d'`.txt"

# merge
robot merge \
  --input ${RUBRIC} \
  --include-annotations true \
  --output rubric-merged-`date '+%Y-%m-%d'`.owl

echo "MERGE DONE."

# add date to IRI version
robot annotate \
  --input rubric-merged-`date '+%Y-%m-%d'`.owl \
  --ontology-iri "http://purl.obolibrary.org/obo/RUBRIC.owl" \
  --version-iri "http://purl.obolibrary.org/obo/`date '+%Y-%m-%d'`/RUBRIC.owl" \
  --output rubric-updated-`date '+%Y-%m-%d'`.owl

echo "VERSION IRI DONE."

# include reasoned triples
robot reason \
	--input rubric-updated-`date '+%Y-%m-%d'`.owl \
  --reasoner HermiT \
  --annotate-inferred-axioms true \
  --output rubric-release-`date '+%Y-%m-%d'`.owl >> ${LOG}

echo "REASONING DONE."

echo "RELEASE DONE."
echo "Please examine intermediate file outputs and replace the OWL file in the root directory"

# run robot report, topsheet to stdout and details to file
robot report --input rubric-release-`date '+%Y-%m-%d'`.owl --output ${LOG} | head -n 5
echo "Release notes can be found here: ${LOG}"
