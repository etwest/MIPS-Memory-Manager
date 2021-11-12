import matplotlib.pyplot as plt

"""
Generate an array which contains the maximum impact
At each step in the memory impact file
"""
def max_impact_arr(file):
	max_impact = []
	reading_header = True
	min_addr = 0
	max_addr = 0

	with open(file) as inFile:
		lines = inFile.readlines()
		for line in lines:
			if line[0]=='#':
				continue
			if reading_header and line == "Memory Profile:\n":
				reading_header = False
				continue

			if reading_header and line != "":
				arr = line.split('=')
				if arr[0] == "min_heap":
					min_addr = int(arr[1], 0)

			if not reading_header:
				addr = int(line, 0) - min_addr
				if addr > max_addr:
					max_addr = addr
				max_impact.append(max_addr)

	return max_impact


if __name__ == "__main__":
	std_impact = max_impact_arr("standard_impact.txt")
	mgr_impact = max_impact_arr("managed_impact.txt")

	plt.plot(std_impact, label='Standard Memory Allocation')
	plt.plot(mgr_impact, label='Managed Memory Allocation')
	plt.legend()
	plt.title("Memory Impact of MergeSort")
	plt.xlabel("Memory Allocations")
	plt.ylabel("Total Memory Impact")
	plt.show()
