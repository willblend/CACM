module Endeca
  class ResultSet < Set

    # display logic (see ticket #290)
    # This should return non-CACM articles representing a wide sample of other
    # journals, weighted by pub.date desc.
    def sample(n=20)
      # remove CACM articles; stop here if we can't produce N results.
      reject! { |a| (a.publication_title == 'Communications of the ACM') }
      return self if size <= n
      
      # get a _minimum_ of n results by popping entire years off the stack,
      # starting with the most recent. again, no need to go further if we
      # can't produce a full N results.
      recent = classify { |r| r.publication_date.year }.sort.reverse.map { |s| s[1] }
      recent = recent.inject [] do |r,set|
        r << set.to_a unless r.flatten.size >= n
        r
      end
      recent = recent.flatten!
      return recent if recent.size <= n
      
      # make buckets of publications, select N results from as many pubs
      # as possible.
      pubs = recent.to_set.classify(&:main_parent_title).values.map(&:to_a)
      returning [] do |results|
        0.upto([n, pubs.flatten.size].min-1) do |i|
          break if pubs.empty?
          pubs = pubs.sort_by { rand } if i%pubs.size == 0
          pub = pubs[i%pubs.size]
          results << pub.delete(pub.rand)
          pubs.delete(pub) if pub.empty?
        end
      end
    end

  end
end