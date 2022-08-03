import json
from Printer import Printer

class JsonPrinter(Printer):

    def __init__(self, report):
        super(JsonPrinter, self).__init__(report)

    def print_report(self):
        error, printed_results = self.filter_results_default(self.report.report)
        if error is not None:
            print(json.dumps(printed_results, sort_keys=True, indent=4))
            print("Scenarios {} are failed!".format(error))
            return

        print("All scenarios are OK!")
