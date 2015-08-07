class String

  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      self.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      self[0] + camelize(self)[1..-1]
    end
  end

  def constantize
    Object.const_get self
  end

end
