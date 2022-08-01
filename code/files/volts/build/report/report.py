import json
import os
import filecmp
from MonitPrinter import MonitPrinter
from Report import Report
from Printer import Printer
from JsonFullPrinter import JsonFullPrinter
from TableFullPrinter import TableFullPrinter
from TablePrinter import TablePrinter
from JsonPrinter import JsonPrinter

#def align_test_results_with_test_list(test_results, test_list):
#    '''
#    Make sure report have all tests results, that was in initial test list
#    '''
#    for actual_test in test_list:
#        if actual_test in test_results:
#            continue
#
#        test_results[actual_test] = {}
#        test_results[actual_test]["status"] = "FAIL"
#        test_results[actual_test]["status_text"] = "Scenario is not present in the results"
#
#    for actual_test in test_results:
#        if actual_test in test_list:
#            continue
#
#        test_results[actual_test]["status"] = "FAIL"
#        test_results[actual_test]["status_text"] = "Scenario is not present in the scenario list"


# Main program starts
try:
    report_file_name = os.environ.get("REPORT_FILE", "result.jsonl")
    report_file_path = r'/opt/report/' + report_file_name

    report = Report(report_file_path)

    printers = []
    print_style = os.environ.get("REPORT_TYPE", "json")
    print_style = print_style.lower()
    if print_style == "json_full":
        printers.append(JsonFullPrinter(report))
    elif print_style == "table_full":
        printers.append(TableFullPrinter(report))
    elif print_style.startswith("table"):
        printers.append(TablePrinter(report))
    else:
        printers.append(JsonPrinter(report))

    printers.append(MonitPrinter(report))

    for printer in printers:
        printer.print_report()

except Exception as e:
    print("Error processing report: {}".format(e))
