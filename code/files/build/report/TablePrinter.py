from Printer import Printer

class TablePrinter(Printer):

    def __init__(self, report):
        super(TablePrinter, self).__init__(report)

    def print_report(self):
        failed_scenarios, printed_results = self.filter_results_default(self.report.report)

        if failed_scenarios is not None:
            print_table(printed_results)
            print("Scenarios {} are failed!".format(failed_scenarios))
            return

        print("All scenarios are OK!")
