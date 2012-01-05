Grading process:

1. Install all the software you need
sudo apt-get install ruby1.9.1-full build-essential pdftk texlive-full
sudo gem install bundler
bundle

2. Change the pset name.
grep -3 -n "stellar_pset_name =" Rakefile

3. Edit the answer grid schema (files/answer_schema.txt)
3a. For each question, list the type (mchoice / tf / file / code) and # points

4. Edit the answer grid (files/answers.txt)
4a. Set the deadline correctly.
4b. Write-in correct answers for multiple-choices and true-false
4c. Add regexps for fill-ins
4d. Replace the regexp for the proof fill-in with this
>files/tex/@_proof.tex

5. Fetch data from Stellar.
rake seed

6. Generate the PDF for proof grading.
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

12. Drop the manual grading results back into files/manual/*.txt

13. Compute totals
rake totals

14. Make students happy
rake post_grades
rake post_feedback
