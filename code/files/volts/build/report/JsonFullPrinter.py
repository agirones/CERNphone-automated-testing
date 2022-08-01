from Printer import Printer

class JsonFullPrinter(Printer):

    def __init__(self, report):
        super(JsonFullPrinter, self).__init__(report)

    def print_report(self):
        failed_scenarios, printed_results = self.filter_results_default(self.report.report)

        print(json.dumps(printed_results, sort_keys=True, indent=4))

        if failed_scenarios is not None:
            print("Scenarios {} are failed!".format(failed_scenarios))
            return

        print("All scenarios are OK!")
