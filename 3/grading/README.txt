Grading process:

1. Install all the software you need
sudo apt-get install ruby1.9.1
sudo gem install bundler
bundle

2. Create the answer grid template
rake answer_grid

3. Edit the answer grid (files/answers.txt)
3a. Set the deadline correctly.
3b. Remove the bad multiple-choices 
3c. Add regexps for fill-ins
3d. Replace the regexp for the proof fill-in with this
>files/tex/@_proof.tex

4. Download the JSON blobs from Gradetacular.
-> files/json/pset.json
-> files/json/critique.json

5. Process the JSON blobs into the on-disk database.
rake seed

6. Generate the PDF for proof grading
rake pdfs

7. Print the PDF for proof grading and hand it to the poor guy grading it.
lpr files/bigfile.pdf

8. Change the code in lateness_score() to reflect the late submission policy.
grep -3 -n "def lateness_score(" Rakefile

9. Grade the auto-graded questions.
rake answers

10. Change the code in grade_code_for() to match the coding problem setup.
grep -3 -n "def grade_code_for(" Rakefile

11. Grade the coding question. This takes hours.
sudo rake codes

12. Drop the manual grading results into files/manual/proof_grades.txt

13. Compute totals
rake totals

14. Change the pset name.
grep -3 -n "stellar_pset_name =" Rakefile

15. Make students happy
rake post_grades
rake post_feedback
