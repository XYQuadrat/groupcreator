import parsecsv
import random
import tables
import json
from os import paramStr, fileExists
from streams import newFileStream
from sequtils import distribute
from itertools import combinations

type
    Student = object
        name: string
        mail: string

proc make_groups(students: seq[Student]): seq[seq[Student]] =
    var input = students
    randomize()
    shuffle(input)

    return input.distribute(int(students.len/2))

proc are_groups_valid(groups: seq[seq[Student]], past_groups: Table[string,seq[string]]): bool =
    for group in groups:
        for pair in combinations(group, 2):
            if past_groups.hasKey(pair[0].mail) and pair[1].mail in past_groups[pair[0].mail]:
                return false
    return true

proc save_groups_to_file(groups: seq[seq[Student]], past_groups: var Table[string,seq[string]]): void =
    for group in groups:
        for pair in combinations(group,2):
            let mail_a : string = pair[0].mail
            let mail_b : string = pair[1].mail

            if mail_a in past_groups:
                past_groups[mail_a].add(mail_b)
            else:
                past_groups[mail_a] = @[mail_b]

            if mail_b in past_groups:
                past_groups[mail_b].add(mail_a)
            else:
                past_groups[mail_b] = @[mail_a]

    writeFile("past_groups.json", $(%*past_groups))
    
proc print_groups(groups: seq[seq[Student]]): void =
    for group in groups:
        for student in group:
            echo student.name & " <" & student.mail & ">"
        echo "" 


var file = newFileStream(paramStr(1), fmRead)

if file == nil:
    quit("Cannot open the file " & paramStr(1))

var parser: CsvParser
var students : seq[Student] = @[]

parser.open(file, paramStr(1))
parser.readHeaderRow()

while parser.readRow():
    students.add(Student(name: parser.rowEntry("Name"), mail: parser.rowEntry("Mail")))
parser.close()

var past_groups : Table[string, seq[string]] = initTable[string, seq[string]]()

if os.fileExists("past_groups.json"):
    var contents : string = readFile("past_groups.json")
    past_groups = to(parseJson(contents),Table[string, seq[string]])

var tries : int = 0
var groups : seq[seq[Student]] = make_groups(students)

while not are_groups_valid(groups, past_groups) and tries < 1000:
    groups = make_groups(students)
    tries += 1

save_groups_to_file(groups, past_groups)
print_groups(groups)